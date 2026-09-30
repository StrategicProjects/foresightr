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
#' @param candidates A list of models with distinct names (see
#'   [with_name()]); by default [candidates_default()]. A candidate that
#'   cannot forecast at every origin and from the whole series is left out,
#'   with a warning.
#' @param period The seasonal period when `y` is a plain vector.
#' @param origins Forecast origins, the last periods of the series.
#' @param horizon Longest horizon forecast and evaluated.
#' @param min_train Observations to train at the first origin; shorter series
#'   get fewer origins.
#' @param window Train on the last `window` observations only, at every
#'   origin and for the final forecast (default: everything before the
#'   origin).
#' @param combine Also evaluate the average of the best `combine` models
#'   (fewer than 2, or more than the candidates left, disables it).
#' @param levels Coverage of the intervals, each above 0 and below 1.
#' @param metric `"mape"`, `"mae"`, `"rmse"` or `"mase"`.
#' @param parallel Fit the origins on several threads: all cores, or as many
#'   as [foresight_threads()] allows. The result is the same either way.
#' @return An object of class `foresight_backtest`, a list with
#'   * `ranking`: one row per candidate that went through the backtest, with
#'     its `score`, whether it was `chosen`, the models involved and a
#'     description; `dropped` names those left out;
#'   * `best`: the name of the chosen candidate;
#'   * `forecast`: the forecast of the chosen candidate with its intervals;
#'   * `candidates`: for each candidate, its `accuracy` by horizon (pairs
#'     evaluated, MAPE, bias, MAE, RMSE, MASE), the relative error `bands`,
#'     the `forecast`, the `cumulative` forecast of totals, the `trajectories`
#'     of the backtest (origins by horizons) and the fitted `params`; an
#'     interval is `NA` at a horizon where every forecast of the backtest was
#'     zero;
#'   * `origins`, `first_origin` (position of the first period forecast),
#'     `horizon`, `metric` and `levels`.
#' @examples
#' bt <- backtest(AirPassengers, origins = 24)
#' bt
#' bt$forecast
#' total_forecast(bt, 6)
#' @export
backtest <- function(y, candidates = candidates_default(), period = NULL, origins = 36,
                     horizon = 12, min_train = 48, window = NULL, combine = 2,
                     levels = c(0.8, 0.95), metric = c("mape", "mae", "rmse", "mase"),
                     parallel = TRUE) {
  series <- as_series(y, period)
  metric <- match.arg(metric)
  if (inherits(candidates, "foresight_model")) candidates <- list(candidates)
  if (!is.list(candidates) || length(candidates) == 0) abort("`candidates` must be a list of models.")
  candidates <- lapply(candidates, check_model, what = "candidates")
  asked <- vapply(candidates, model_name, "")
  if (anyDuplicated(asked)) {
    abort("candidates must have distinct names; rename with `with_name()`: ",
          paste(unique(asked[duplicated(asked)]), collapse = ", "), ".")
  }
  if (!is.numeric(levels) || anyNA(levels) || any(levels <= 0 | levels >= 1)) {
    abort("`levels` must be above 0 and below 1, e.g. 0.8 for an 80% interval.")
  }
  levels <- as.numeric(levels)
  if (anyDuplicated(level_names(levels))) abort("`levels` must differ from one another.")
  origins <- check_count(origins, "origins", min = 1)
  horizon <- check_count(horizon, "horizon", min = 1)
  min_train <- check_count(min_train, "min_train", min = 1)
  usable <- min(origins, max(length(series$values) - min_train, 0))
  if (usable < horizon) {
    abort("the series is too short: ", length(series$values), " observations with `min_train` = ",
          min_train, " leave ", usable, " origins, fewer than the horizon (", horizon,
          "); lower `min_train` or `horizon`.")
  }
  raw <- rs_backtest(series$values, series$period, series$phase, unname(candidates),
                     origins, horizon, min_train,
                     if (is.null(window)) NaN else check_count(window, "window", min = 1),
                     check_count(combine, "combine"), levels, metric,
                     check_flag(parallel, "parallel"))
  names_ <- vapply(raw$candidates, function(c) c$name, "")
  dropped <- setdiff(asked, names_)
  if (length(dropped)) {
    warning("left out of the backtest (no forecast at some origin or from the whole series): ",
            paste(dropped, collapse = ", "), call. = FALSE)
  }
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
    dropped = dropped,
    origins = raw$origins,
    first_origin = raw$first_origin,
    horizon = raw$horizon,
    metric = metric,
    levels = raw$levels,
    series = c(series["tsp"], list(values = series$values))
  ), class = "foresight_backtest")
}

# `lower` and `upper` come row by row, one value per level; NA where a row
# has no interval (no usable error at that horizon).
interval_columns <- function(mean, lower, upper, levels, rows) {
  out <- data.frame(mean = mean)
  if (rows == 0 || length(levels) == 0) return(out)
  lower <- na(by_row(lower, rows))
  upper <- na(by_row(upper, rows))
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
  forecast <- data.frame(horizon = seq_along(c$mean))
  if (!is.null(times)) forecast$time <- times
  forecast <- cbind(forecast, interval_columns(c$mean, c$lower, c$upper, levels,
                                               length(c$mean)))
  cumulative <- cbind(data.frame(periods = seq_along(c$cumulative_mean)),
                      interval_columns(c$cumulative_mean, c$cumulative_lower,
                                       c$cumulative_upper, levels, length(c$cumulative_mean)))
  bands <- function(lower, upper) {
    cbind(data.frame(horizon = seq_len(h)),
          interval_columns(rep(0, h), lower, upper, levels, h)[-1])
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
#' @examples
#' bt <- backtest(AirPassengers, list(model_theta(), model_seasonal_naive()), origins = 24)
#' total_forecast(bt, 6)
#' colSums(bt$forecast[1:6, c("mean", "lower_80", "upper_80")])  # wider, and wrong
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
