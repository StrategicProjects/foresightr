#' Gaps and outliers
#'
#' `fill_gaps()` fills missing values, following the seasonal pattern when
#' there is one. `find_outliers()` finds the observations far from what the
#' trend and the season suggest, and what they should rather be.
#' `clean_series()` does both.
#'
#' @param y A `ts` or a numeric vector, possibly with `NA`.
#' @param period The seasonal period, when `y` is a plain vector.
#' @return `fill_gaps()` and `clean_series()`: the series, a `ts` when `y` is
#'   one. `find_outliers()`: a data frame with the `index` (from 1), the
#'   `value` and its `replacement`, plus the `time` for a `ts`.
#' @examples
#' y <- log(AirPassengers)
#' y[c(30, 100)] <- y[c(30, 100)] + c(0.8, -0.7)
#' y[60] <- NA
#' find_outliers(y)
#' clean_series(y)[c(30, 60, 100)]
#' @export
fill_gaps <- function(y, period = NULL) {
  series <- as_series(y, period, missing = TRUE)
  along(rs_interpolate(series$values, series$period), series)
}

#' @rdname fill_gaps
#' @export
find_outliers <- function(y, period = NULL) {
  series <- as_series(y, period, missing = TRUE)
  raw <- rs_outliers(series$values, series$period)
  out <- data.frame(index = raw$index, value = raw$value, replacement = raw$replacement)
  if (!is.null(series$tsp)) {
    out$time <- series$tsp[1] + (out$index - 1) / series$tsp[3]
    out <- out[c("index", "time", "value", "replacement")]
  }
  out
}

#' @rdname fill_gaps
#' @export
clean_series <- function(y, period = NULL) {
  series <- as_series(y, period, missing = TRUE)
  along(rs_clean(series$values, series$period), series)
}

#' Tests and transformations
#'
#' * `kpss_statistic()`: the KPSS statistic for level stationarity
#'   (Kwiatkowski et al., 1992); above 0.463 a difference is called for at
#'   5%.
#' * `n_differences()`: differences needed by repeated KPSS tests.
#' * `n_seasonal_differences()`: seasonal differences needed, by the
#'   strength of seasonality.
#' * `seasonal_strength()`: from 0 to 1 (Wang, Smith & Hyndman, 2006).
#' * `autocorrelations()`: at lags 1 to `max_lag`.
#' * `box_cox()`, `inv_box_cox()`: the transformation and its inverse;
#'   `guerrero_lambda()` chooses lambda by Guerrero's method (1993).
#'
#' @param y,x A `ts` or a numeric vector.
#' @param period The seasonal period, when `y` is a plain vector.
#' @param max Most differences.
#' @param max_lag Largest lag.
#' @param lambda The Box-Cox parameter; 0 is the log.
#' @return A number, or the transformed values.
#' @examples
#' kpss_statistic(log(AirPassengers))
#' n_differences(log(AirPassengers))
#' guerrero_lambda(AirPassengers)
#' @export
kpss_statistic <- function(y) na(rs_kpss(check_numbers(y, "y")))

#' @rdname kpss_statistic
#' @export
n_differences <- function(y, max = 2) {
  rs_ndiffs(check_numbers(y, "y"), check_count(max, "max", max = 5))
}

#' @rdname kpss_statistic
#' @export
n_seasonal_differences <- function(y, period = NULL) {
  series <- as_series(y, period)
  rs_nsdiffs(series$values, series$period)
}

#' @rdname kpss_statistic
#' @export
seasonal_strength <- function(y, period = NULL) {
  series <- as_series(y, period)
  na(rs_seasonal_strength(series$values, series$period))
}

#' @rdname kpss_statistic
#' @export
autocorrelations <- function(y, max_lag) {
  na(rs_acf(check_numbers(y, "y"), check_count(max_lag, "max_lag", min = 1)))
}

#' @rdname kpss_statistic
#' @export
box_cox <- function(x, lambda) {
  out <- rs_box_cox(check_numbers(x, "x", missing = TRUE), check_number(lambda, "lambda"), FALSE)
  if (stats::is.ts(x)) stats::ts(out, start = stats::start(x), frequency = stats::frequency(x)) else out
}

#' @rdname kpss_statistic
#' @export
inv_box_cox <- function(x, lambda) {
  out <- rs_box_cox(check_numbers(x, "x", missing = TRUE), check_number(lambda, "lambda"), TRUE)
  if (stats::is.ts(x)) stats::ts(out, start = stats::start(x), frequency = stats::frequency(x)) else out
}

#' @rdname kpss_statistic
#' @export
guerrero_lambda <- function(y, period = NULL) {
  series <- as_series(y, period)
  na(rs_guerrero(series$values, series$period, series$phase))
}

#' Accuracy of forecasts
#'
#' `mape()` is the mean absolute percentage error and `pct_bias()` the mean
#' of (forecast - actual) / actual, both in percent; `mae()` and `rmse()` are
#' the mean absolute and root mean squared errors; `mase()` scales the mean
#' absolute error by the in-sample error of the seasonal naive forecast on
#' `train` (Hyndman & Koehler, 2006).
#'
#' @param actual,forecast Numeric vectors of the same length.
#' @param train The history the forecasts were made from, for `mase()`.
#' @param period Its seasonal period.
#' @return A number (`NA` when it cannot be computed).
#' @examples
#' mape(c(100, 200), c(110, 180))
#' @export
mape <- function(actual, forecast) accuracy_of(actual, forecast, "mape")

#' @rdname mape
#' @export
pct_bias <- function(actual, forecast) accuracy_of(actual, forecast, "bias")

#' @rdname mape
#' @export
mae <- function(actual, forecast) accuracy_of(actual, forecast, "mae")

#' @rdname mape
#' @export
rmse <- function(actual, forecast) accuracy_of(actual, forecast, "rmse")

#' @rdname mape
#' @export
mase <- function(actual, forecast, train, period = 1) {
  pair <- paired(actual, forecast)
  na(rs_mase(pair[[1]], pair[[2]], check_numbers(train, "train"),
             check_count(period, "period", min = 1)))
}

paired <- function(actual, forecast) {
  actual <- check_numbers(actual, "actual")
  forecast <- check_numbers(forecast, "forecast")
  if (length(actual) != length(forecast)) abort("`actual` and `forecast` differ in length.")
  list(actual, forecast)
}

accuracy_of <- function(actual, forecast, measure) {
  pair <- paired(actual, forecast)
  na(rs_accuracy(pair[[1]], pair[[2]], measure))
}

#' External variables for a regression with ARIMA errors
#'
#' `fourier_terms()` gives the sine and cosine pairs of a seasonal period up
#' to `order` harmonics (those beyond half the period, which would repeat
#' the earlier ones, are left out); `seasonal_dummies()` one dummy per season
#' but the first. Both have `rows` rows, which must cover the series and the horizon
#' to be forecast. Combine them, or add your own columns, with [cbind()].
#'
#' @param period The seasonal period (need not be a whole number for Fourier
#'   terms).
#' @param order Harmonics.
#' @param rows Rows: the length of the series plus the horizon.
#' @return A data frame.
#' @examples
#' x <- fourier_terms(12, 3, length(AirPassengers) + 12)
#' fit <- fit_model(model_arima(c(1, 1, 1), constant = TRUE, regressors = x), log(AirPassengers))
#' predict(fit, 12)
#' @export
fourier_terms <- function(period, order, rows) {
  period <- check_number(period, "period")
  if (period <= 1) abort("`period` must be above 1.")
  as.data.frame(rs_fourier(period, check_count(order, "order", min = 1, max = 1000),
                           check_count(rows, "rows", min = 1, max = 1e7)))
}

#' @rdname fourier_terms
#' @export
seasonal_dummies <- function(period, rows) {
  as.data.frame(rs_seasonal_dummies(check_count(period, "period", min = 2, max = 1000),
                                    check_count(rows, "rows", min = 1, max = 1e7)))
}

as_regressors <- function(x) {
  if (is.null(x)) return(NULL)
  if (is.matrix(x)) x <- as.data.frame(x)
  if (!is.list(x) || is.null(names(x)) || any(names(x) == "")) {
    abort("`regressors` must be a data frame, matrix or list with named numeric columns.")
  }
  lapply(x, function(column) check_numbers(column, "regressors"))
}
