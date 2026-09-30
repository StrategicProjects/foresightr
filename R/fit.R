#' Fit a model and forecast
#'
#' `fit_model()` estimates a model on a series and keeps what was estimated;
#' [predict()][predict.foresight_fit] forecasts from it. `forecast_model()`
#' does both in one go.
#'
#' @param model A model, e.g. [model_theta()].
#' @param y A `ts` or a numeric vector.
#' @param period The seasonal period when `y` is a plain vector (1 for none);
#'   a `ts` brings its own.
#' @param h Periods to forecast.
#' @return `fit_model()`: an object of class `foresight_fit`, a list with the
#'   model name and description, the estimated `params` (named numeric),
#'   `log_likelihood`, `aic`, `aicc`, `bic` and `residuals` when the model has
#'   them (`NA` otherwise), and `details`: orders and coefficients for ARIMA,
#'   the code and smoothing for ETS, changepoints and event effects for
#'   Prophet, the structure for TBATS. `forecast_model()`: the forecasts, a
#'   `ts` when `y` is one.
#' @details The estimate lives in memory: a fit restored with `readRDS()`
#'   cannot forecast and has to be fitted again.
#' @examples
#' fit <- fit_model(model_log(model_airline()), AirPassengers)
#' predict(fit, h = 12)
#' forecast_model(model_theta(), AirPassengers, h = 3)
#' @export
fit_model <- function(model, y, period = NULL) {
  check_model(model)
  series <- as_series(y, period)
  raw <- rs_fit(model, series$values, series$period, series$phase)
  details <- lapply(raw$details, function(d) {
    if (is.list(d) && identical(names(d), c("names", "values"))) {
      stats::setNames(d$values, d$names)
    } else if (is.numeric(d)) {
      na(d)
    } else {
      d
    }
  })
  structure(list(
    model = raw$model,
    description = raw$description,
    params = stats::setNames(raw$params$values, raw$params$names),
    log_likelihood = na(raw$log_likelihood),
    aic = na(raw$aic),
    aicc = na(raw$aicc),
    bic = na(raw$bic),
    residuals = if (length(raw$residuals)) raw$residuals else NULL,
    details = details,
    series = series[c("period", "phase", "tsp")],
    pointer = raw$pointer
  ), class = "foresight_fit")
}

#' @rdname fit_model
#' @param object A fit from `fit_model()`.
#' @param ... Not used.
#' @export
predict.foresight_fit <- function(object, h = 12, ...) {
  h <- check_count(h, "h", min = 1)
  after(rs_predict(object$pointer, h), object$series)
}

#' @rdname fit_model
#' @export
forecast_model <- function(model, y, h = 12, period = NULL) {
  check_model(model)
  series <- as_series(y, period)
  h <- check_count(h, "h", min = 1)
  after(rs_forecast(model, series$values, series$period, series$phase, h), series)
}

#' @export
print.foresight_fit <- function(x, ...) {
  cat("<foresight fit> ", x$model, "\n", x$description, "\n", sep = "")
  if (length(x$params)) {
    cat("\nParameters:\n")
    print(signif(x$params, 5))
  }
  criteria <- c(log_likelihood = x$log_likelihood, aic = x$aic, aicc = x$aicc, bic = x$bic)
  criteria <- criteria[!is.na(criteria)]
  if (length(criteria)) {
    cat("\n")
    print(signif(criteria, 7))
  }
  invisible(x)
}
