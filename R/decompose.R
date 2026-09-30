#' Decompose a series by STL or MSTL
#'
#' `decompose_stl()` splits a series into trend, seasonal pattern and
#' remainder by LOESS (Cleveland, Cleveland, McRae & Terpenning, 1990);
#' its defaults are those of [stats::stl()] and its numbers agree with it.
#' `decompose_mstl()` applies STL in turn to each of several seasonal periods
#' (Bandara, Hyndman & Bergmeir, 2021).
#'
#' @param y A `ts` or a numeric vector.
#' @param period The seasonal period, when `y` is a plain vector.
#' @param seasonal_window The LOESS window over the cycles, an odd number of
#'   at least 7: the smaller, the faster the pattern may change. `NULL`
#'   keeps the same pattern in every cycle (`s.window = "periodic"`).
#' @param trend_window,low_pass_window LOESS windows of the trend and of the
#'   low-pass filter.
#' @param degrees LOESS degrees (0 or 1) of the seasonal, trend and low-pass
#'   smoothers; default `c(0, 1, 1)`.
#' @param robust Down-weight outliers.
#' @param inner,outer Passes of the inner loop and robustness rounds.
#' @return An object of class `foresight_decomposition`, a list with
#'   `trend`, `seasonal` (a matrix, one column per period), `remainder`,
#'   `seasonally_adjusted`, `periods`, `trend_strength` and
#'   `seasonal_strength` (from 0 to 1; Wang, Smith & Hyndman, 2006).
#' @examples
#' d <- decompose_stl(log(AirPassengers), seasonal_window = 13)
#' d$seasonal_strength
#' plot(d)
#' @export
decompose_stl <- function(y, period = NULL, seasonal_window = NULL, trend_window = NULL,
                          low_pass_window = NULL, degrees = NULL, robust = FALSE, inner = NULL,
                          outer = NULL) {
  series <- as_series(y, period)
  optional <- function(x, what, min = 1) {
    if (is.null(x)) NaN else check_count(x, what, min = min)
  }
  raw <- rs_stl(series$values, series$period, optional(seasonal_window, "seasonal_window", 3),
                optional(trend_window, "trend_window"),
                optional(low_pass_window, "low_pass_window"),
                check_counts(degrees %||% numeric(0), "degrees"),
                check_flag(robust, "robust"), optional(inner, "inner"),
                optional(outer, "outer", 0))
  decomposition(raw, series)
}

#' @rdname decompose_stl
#' @param periods Seasonal periods.
#' @param windows Seasonal windows, one per period in increasing order of
#'   period (default 11, 15, 19, ...).
#' @param iterations Rounds over the periods (default 2).
#' @export
decompose_mstl <- function(y, periods = NULL, windows = NULL, iterations = NULL,
                           robust = FALSE) {
  series <- as_series(y)
  periods <- check_counts(periods %||% series$period, "periods")
  raw <- rs_mstl(series$values, periods, check_counts(windows %||% numeric(0), "windows"),
                 if (is.null(iterations)) NaN else check_count(iterations, "iterations", min = 1),
                 check_flag(robust, "robust"))
  decomposition(raw, series)
}

decomposition <- function(raw, series) {
  seasonal <- do.call(cbind, raw$seasonal)
  if (is.null(seasonal)) seasonal <- matrix(numeric(0), length(raw$trend), 0)
  colnames(seasonal) <- paste0("seasonal_", raw$periods)
  adjusted <- series$values - rowSums(seasonal)
  if (!is.null(series$tsp)) {
    seasonal <- stats::ts(seasonal, start = series$tsp[1], frequency = series$tsp[3])
  }
  structure(list(
    trend = along(raw$trend, series),
    seasonal = seasonal,
    remainder = along(raw$remainder, series),
    seasonally_adjusted = along(adjusted, series),
    periods = raw$periods,
    trend_strength = raw$trend_strength,
    seasonal_strength = stats::setNames(na(raw$seasonal_strength), colnames(seasonal))
  ), class = "foresight_decomposition")
}

#' @export
print.foresight_decomposition <- function(x, ...) {
  cat("<foresight decomposition> ", length(x$trend), " observations, period",
      if (length(x$periods) > 1) "s", " ", paste(x$periods, collapse = ", "), "\n", sep = "")
  cat("Strength of the trend: ", format(x$trend_strength, digits = 3), "\n", sep = "")
  for (i in seq_along(x$periods)) {
    cat("Strength of seasonality (", x$periods[i], "): ",
        format(x$seasonal_strength[i], digits = 3), "\n", sep = "")
  }
  invisible(x)
}

#' @export
as.data.frame.foresight_decomposition <- function(x, ...) {
  data.frame(trend = as.numeric(x$trend), unclass(as.matrix(x$seasonal)),
             remainder = as.numeric(x$remainder))
}

#' @export
plot.foresight_decomposition <- function(x, ...) {
  parts <- cbind(data = x$seasonally_adjusted + rowSums(as.matrix(x$seasonal)),
                 trend = x$trend, x$seasonal, remainder = x$remainder)
  if (!stats::is.ts(parts)) parts <- stats::ts(parts)
  graphics::plot(parts, main = "", ...)
  invisible(x)
}
