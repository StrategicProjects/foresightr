#' Choose a model by what would have worked
#'
#' Replays the past with each candidate: at each of the last `origins`
#' periods the model is fitted on the data before it and forecasts up to
#' `horizon` periods ahead. The candidates are ranked by the average error
#' (`metric`) over the horizons, the simple average of the best `combine` is
#' added as one more candidate, and every candidate forecasts from the whole
#' series with intervals taken from the errors it made: quantiles of the
#' relative error at each horizon, and of the relative error of totals for
#' the forecast of the next k periods together.
#'
#' @param y A `ts` or a numeric vector.
#' @param candidates A list of models; see [candidates_default()].
#' @param period The seasonal period when `y` is a plain vector.
#' @param origins Forecast origins, the last periods of the series.
#' @param horizon Longest horizon forecast and evaluated.
#' @param min_train Observations to train at the first origin; shorter series
#'   get fewer origins.
#' @param window Train on the last `window` observations only (default:
#'   everything before the origin).
#' @param combine Also evaluate the average of the best `combine` models
#'   (fewer than 2 disables it).
#' @param levels Coverage of the intervals.
#' @param metric `"mape"`, `"mae"`, `"rmse"` or `"mase"`.
#' @param parallel Fit the origins on all cores. The result is the same
#'   either way.
#' @return An object of class `foresight_backtest`, a list with
#'   * `ranking`: one row per candidate with its `score`, whether it was
#'     `chosen`, the models involved and a description;
#'   * `best`: the name of the chosen candidate;
#'   * `forecast`: the forecast of the chosen candidate with its intervals;
#'   * `candidates`: for each candidate, its `accuracy` by horizon (pairs
#'     evaluated, MAPE, bias, MAE, RMSE, MASE), the relative error `bands`,
#'     the `forecast`, the `cumulative` forecast of totals, the `trajectories`
#'     of the backtest (origins by horizons) and the fitted `params`;
#'   * `origins`, `first_origin` (position of the first period forecast),
#'     `horizon`, `metric` and `levels`.
#' @examples
#' \donttest{
#' bt <- backtest(AirPassengers, origins = 24)
#' bt
#' bt$forecast
#' total_forecast(bt, 6)
#' }
#' @export
backtest <- function(y, candidates = candidates_default(), period = NULL, origins = 36,
                     horizon = 12, min_train = 48, window = NULL, combine = 2,
                     levels = c(0.8, 0.95), metric = c("mape", "mae", "rmse", "mase"),
                     parallel = TRUE) {
  series <- as_series(y, period)
  if (inherits(candidates, "foresight_model")) candidates <- list(candidates)
  if (!is.list(candidates) || length(candidates) == 0) abort("`candidates` must be a list of models.")
  candidates <- lapply(candidates, check_model, what = "candidates")
  if (!is.numeric(levels) || anyNA(levels) || any(levels <= 0 | levels >= 1)) {
    abort("`levels` must be between 0 and 1.")
  }
  raw <- rs_backtest(series$values, series$period, series$phase, unname(candidates),
                     check_count(origins, "origins", min = 1),
                     check_count(horizon, "horizon", min = 1),
                     check_count(min_train, "min_train", min = 1),
                     if (is.null(window)) NaN else check_count(window, "window", min = 1),
                     check_count(combine, "combine"),
                     as.numeric(levels), match.arg(metric),
                     check_flag(parallel, "parallel"))
  names_ <- vapply(raw$candidates, function(c) c$name, "")
  reports <- stats::setNames(lapply(raw$candidates, candidate_report, raw = raw, series = series),
                             names_)
  ranking <- data.frame(
    name = names_,
    score = vapply(raw$candidates, function(c) c$score, 0),
    chosen = seq_along(names_) == raw$chosen,
    components = vapply(raw$candidates, function(c) paste(c$components, collapse = " + "), ""),
    description = vapply(raw$candidates, function(c) c$description, ""),
    stringsAsFactors = FALSE
  )
  structure(list(
    ranking = ranking,
    best = names_[raw$chosen],
    forecast = reports[[raw$chosen]]$forecast,
    candidates = reports,
    origins = raw$origins,
    first_origin = raw$first_origin,
    horizon = raw$horizon,
    metric = match.arg(metric),
    levels = raw$levels,
    series = c(series["tsp"], list(values = series$values))
  ), class = "foresight_backtest")
}

interval_columns <- function(mean, lower, upper, levels, rows) {
  lower <- by_row(lower, rows)
  upper <- by_row(upper, rows)
  out <- data.frame(mean = mean)
  for (j in seq_along(levels)) {
    out[[paste0("lower_", level_names(levels[j]))]] <- lower[, j]
    out[[paste0("upper_", level_names(levels[j]))]] <- upper[, j]
  }
  out
}

candidate_report <- function(c, raw, series) {
  h <- length(c$mape)
  levels <- raw$levels
  times <- times_after(length(c$mean), series)
  forecast <- cbind(data.frame(horizon = seq_along(c$mean)),
                    if (!is.null(times)) data.frame(time = times),
                    interval_columns(c$mean, c$lower, c$upper, levels, length(c$mean)))
  cumulative <- cbind(data.frame(periods = seq_along(c$cumulative_mean)),
                      interval_columns(c$cumulative_mean, c$cumulative_lower,
                                       c$cumulative_upper, levels, length(c$cumulative_mean)))
  bands <- function(lower, upper) {
    out <- data.frame(horizon = seq_len(h))
    lower <- by_row(lower, h)
    upper <- by_row(upper, h)
    for (j in seq_along(levels)) {
      out[[paste0("lower_", level_names(levels[j]))]] <- lower[, j]
      out[[paste0("upper_", level_names(levels[j]))]] <- upper[, j]
    }
    out
  }
  list(
    name = c$name,
    description = c$description,
    components = c$components,
    score = c$score,
    params = stats::setNames(c$params$values, c$params$names),
    accuracy = data.frame(horizon = seq_len(h), n = c$n, mape = na(c$mape), bias = na(c$bias),
                          mae = na(c$mae), rmse = na(c$rmse), mase = na(c$mase)),
    bands = bands(c$band_lower, c$band_upper),
    cumulative_bands = bands(c$cumulative_band_lower, c$cumulative_band_upper),
    forecast = forecast,
    cumulative = cumulative,
    trajectories = by_row(c$trajectories, raw$origins)
  )
}

#' Forecast of a total
#'
#' The forecast of the sum of the next `k` periods, with intervals measured
#' on totals in the backtest. Adding up the limits of each period would
#' overstate the uncertainty of a total.
#'
#' @param backtest A result of [backtest()].
#' @param k Periods added up.
#' @param candidate A candidate name; by default the chosen one.
#' @return A one-row data frame: `periods`, `mean` and the bounds of each
#'   interval.
#' @export
total_forecast <- function(backtest, k, candidate = backtest$best) {
  if (!inherits(backtest, "foresight_backtest")) abort("`backtest` must be a result of backtest().")
  report <- backtest$candidates[[candidate]]
  if (is.null(report)) abort("no candidate named ", candidate, ".")
  k <- check_count(k, "k", min = 1)
  if (k > nrow(report$cumulative)) abort("`k` goes beyond the horizon (", nrow(report$cumulative), ").")
  out <- report$cumulative[k, , drop = FALSE]
  rownames(out) <- NULL
  out
}

#' @export
print.foresight_backtest <- function(x, n = 10, ...) {
  cat("<foresight backtest> ", nrow(x$ranking), " candidates, ", x$origins, " origins, ",
      x$horizon, " periods ahead\n", sep = "")
  cat("Chosen: ", x$best, " (", toupper(x$metric), " ",
      format(x$ranking$score[x$ranking$chosen], digits = 4), ")\n\n", sep = "")
  ranking <- x$ranking[order(x$ranking$score), c("name", "score")]
  rownames(ranking) <- NULL
  print(utils::head(ranking, n), digits = 4)
  if (nrow(ranking) > n) cat("... and ", nrow(ranking) - n, " more\n", sep = "")
  invisible(x)
}

#' @export
as.data.frame.foresight_backtest <- function(x, ...) x$ranking

#' Plot a backtest
#'
#' The last years of the series and the forecast of the chosen candidate
#' with its widest interval.
#'
#' @param x A result of [backtest()].
#' @param candidate A candidate name; by default the chosen one.
#' @param history How many of the last observations to show.
#' @param ... Passed to [plot()].
#' @return `x`, invisibly.
#' @export
plot.foresight_backtest <- function(x, candidate = x$best, history = 48, ...) {
  report <- x$candidates[[candidate]]
  if (is.null(report)) abort("no candidate named ", candidate, ".")
  y <- x$series$values
  n <- length(y)
  shown <- max(1, n - history + 1):n
  tsp <- x$series$tsp
  time <- if (is.null(tsp)) seq_len(n) else tsp[1] + (seq_len(n) - 1) / tsp[3]
  ahead <- if (is.null(tsp)) n + report$forecast$horizon else report$forecast$time
  level <- level_names(max(x$levels))
  lower <- report$forecast[[paste0("lower_", level)]]
  upper <- report$forecast[[paste0("upper_", level)]]
  graphics::plot(c(time[shown], ahead), c(y[shown], rep(NA, length(ahead))),
                 type = "l", ylim = range(y[shown], lower, upper, finite = TRUE),
                 xlab = "", ylab = "", main = report$name, ...)
  graphics::polygon(c(ahead, rev(ahead)), c(lower, rev(upper)),
                    col = grDevices::adjustcolor("#4C6FFF", 0.2), border = NA)
  graphics::lines(ahead, report$forecast$mean, col = "#4C6FFF", lwd = 2)
  invisible(x)
}
