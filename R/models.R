# Model specifications: plain lists with class `foresight_model`. The Rust
# side builds the model from them at every fit, so they can be saved,
# printed and combined freely.

new_model <- function(kind, ...) {
  fields <- list(...)
  fields <- fields[!vapply(fields, is.null, logical(1))]
  structure(c(list(kind = kind), fields), class = "foresight_model")
}

check_model <- function(model, what = "model") {
  if (!inherits(model, "foresight_model")) {
    abort("`", what, "` must be a model, e.g. `model_theta()`.")
  }
  model
}

#' Benchmark models
#'
#' The yardsticks every other model must beat.
#'
#' * `model_mean()`: the mean of the history.
#' * `model_naive()`: the last value (random walk).
#' * `model_drift()`: the last value plus the average change (random walk
#'   with drift).
#' * `model_seasonal_naive()`: the same season of the last cycle; with
#'   `growth = TRUE`, scaled by the growth of the last cycle over the one
#'   before.
#'
#' @param growth Scale by the growth of the last cycle.
#' @return A model specification, to use with [fit_model()],
#'   [forecast_model()] or [backtest()].
#' @family models
#' @examples
#' forecast_model(model_seasonal_naive(), AirPassengers, h = 3)
#' @export
model_mean <- function() new_model("mean")

#' @rdname model_mean
#' @export
model_naive <- function() new_model("naive")

#' @rdname model_mean
#' @export
model_drift <- function() new_model("drift")

#' @rdname model_mean
#' @export
model_seasonal_naive <- function(growth = FALSE) {
  new_model("seasonal_naive", growth = check_flag(growth, "growth"))
}

#' Theta method
#'
#' The Theta method (Assimakopoulos & Nikolopoulos, 2000), equivalent to
#' simple exponential smoothing with drift, applied to the series seasonally
#' adjusted by classical multiplicative decomposition when it is seasonal.
#'
#' @inherit model_mean return
#' @family models
#' @examples
#' forecast_model(model_theta(), AirPassengers, h = 3)
#' @export
model_theta <- function() new_model("theta")

#' Holt-Winters
#'
#' Holt-Winters with multiplicative seasonality, the smoothing parameters
#' chosen by the squared error of the one-step forecasts. The series must be
#' positive and cover three cycles.
#'
#' @inherit model_mean return
#' @family models
#' @examples
#' fit_model(model_holt_winters(), AirPassengers)$params
#' @export
model_holt_winters <- function() new_model("holt_winters")

#' Log-linear regression
#'
#' Regression of the log of the series on a linear trend and seasonal
#' dummies, brought back with Duan's smearing correction.
#'
#' @param window Fit on the last `window` observations only.
#' @param deflator A price index to deflate by before fitting, one value per
#'   period from the first observation on. The future of the index is not
#'   read: the forecasts are inflated back at its growth over the last cycle.
#' @inherit model_mean return
#' @family models
#' @examples
#' forecast_model(model_log_linear(window = 60), AirPassengers, h = 3)
#' @export
model_log_linear <- function(window = NULL, deflator = NULL) {
  if (!is.null(deflator)) deflator <- check_numbers(deflator, "deflator")
  new_model("log_linear", window = check_count(window, "window", min = 1, null = TRUE),
            deflator = deflator)
}

#' Seasonal ARIMA
#'
#' ARIMA(p, d, q)(P, D, Q) estimated by exact Gaussian maximum likelihood (the
#' innovations algorithm), from three starting points. `model_airline()` is
#' ARIMA(0,1,1)(0,1,1), a good default for seasonal series, usually on the log
#' scale ([model_log()]).
#'
#' @param order (p, d, q).
#' @param seasonal (P, D, Q), ignored for series without seasonality.
#' @param constant Estimate a mean (series not differenced) or a drift (one
#'   difference). By default only the mean is estimated.
#' @param regressors External variables, a data frame, matrix or named list of
#'   numeric columns with one row per period from the first observation on;
#'   to forecast, the rows must also cover the horizon. The model becomes a
#'   regression with ARIMA errors. See [fourier_terms()].
#' @inherit model_mean return
#' @family models
#' @examples
#' fit <- fit_model(model_airline(), log(AirPassengers))
#' fit$details$seasonal_ma
#' @export
model_arima <- function(order = c(0, 1, 1), seasonal = c(0, 0, 0), constant = NULL,
                        regressors = NULL) {
  order <- check_counts(order, "order", n = 3, max = 50)
  seasonal <- check_counts(seasonal, "seasonal", n = 3, max = 50)
  if (order[2] > 5 || seasonal[2] > 5) abort("at most 5 differences of each kind.")
  new_model("arima", order = order, seasonal = seasonal,
            constant = check_flag(constant, "constant", null = TRUE),
            regressors = as_regressors(regressors))
}

#' @rdname model_arima
#' @export
model_airline <- function() model_arima(c(0, 1, 1), c(0, 1, 1))

#' ARIMA with automatic orders
#'
#' Differences chosen by the KPSS test and by the strength of seasonality,
#' orders by a stepwise search on the information criterion (Hyndman &
#' Khandakar, 2008). In a backtest the choice is made again at every origin,
#' so the whole procedure is judged, not one lucky specification.
#'
#' @param criterion `"aicc"`, `"aic"` or `"bic"`.
#' @param d,seasonal_d Fix the number of differences instead of testing.
#' @param max_order Largest p, q, P and Q.
#' @inheritParams model_arima
#' @inherit model_mean return
#' @family models
#' @examples
#' fit <- fit_model(model_auto_arima(), log(AirPassengers))
#' fit$details$order
#' fit$details$seasonal_order
#' @export
model_auto_arima <- function(criterion = c("aicc", "aic", "bic"), d = NULL, seasonal_d = NULL,
                             max_order = c(5, 5, 2, 2), regressors = NULL) {
  new_model("auto_arima", criterion = match.arg(criterion),
            d = check_count(d, "d", max = 5, null = TRUE),
            seasonal_d = check_count(seasonal_d, "seasonal_d", max = 5, null = TRUE),
            max_order = check_counts(max_order, "max_order", n = 4, max = 50),
            regressors = as_regressors(regressors))
}

#' Exponential smoothing
#'
#' A member of the exponential smoothing family in state space form
#' (Hyndman et al., 2008), by its code: error (`A`, `M`), trend (`N`, `A`,
#' `Ad`) and season (`N`, `A`, `M`), such as `"MAM"` or `"AAdN"`.
#' `model_auto_ets()` chooses the member with the best criterion;
#' multiplicative parts only for positive series.
#'
#' @param code The model, e.g. `"MAM"`.
#' @inheritParams model_auto_arima
#' @inherit model_mean return
#' @family models
#' @examples
#' fit <- fit_model(model_auto_ets(), AirPassengers)
#' fit$details$code
#' @export
model_ets <- function(code) {
  if (!is.character(code) || length(code) != 1) abort("`code` must be a string such as \"MAM\".")
  new_model("ets", code = code)
}

#' @rdname model_ets
#' @export
model_auto_ets <- function(criterion = c("aicc", "aic", "bic")) {
  new_model("auto_ets", criterion = match.arg(criterion))
}

#' Prophet-style trend with changepoints and events
#'
#' The model of Taylor & Letham (2018) fitted without Stan: a piecewise
#' linear trend whose changes of slope are shrunk by a Laplace prior (those
#' that do not matter come out as exactly zero), Fourier seasonality, and
#' optional events and lasting steps.
#'
#' @param changepoints Potential changepoints (default 25).
#' @param changepoint_range Share of the history where they may fall
#'   (default 0.8).
#' @param changepoint_prior_scale,seasonality_prior_scale,event_prior_scale
#'   Scales of the priors (defaults 0.05, 10 and 10).
#' @param fourier_order Harmonics of the seasonal pattern (default: 10 for
#'   yearly patterns, at most half the period).
#' @param events Named list: for each event, the positions where it happens,
#'   counted from 1 at the first observation, future ones included.
#'   Seasonal terms are fitted from two full cycles on.
#' @param steps Named list: for each lasting change of level, the position
#'   from which it applies.
#' @inherit model_mean return
#' @family models
#' @examples
#' # ten years of monthly sales with a campaign every other November (+20)
#' # and a lasting change of level from the 81st month on (-15)
#' t <- 1:120
#' sales <- 200 + 0.8 * t + 5 * sin(2 * pi * t / 12)
#' campaigns <- c(11, 35, 59, 83, 107)
#' sales[campaigns] <- sales[campaigns] + 20
#' sales[t >= 81] <- sales[t >= 81] - 15
#' # the campaign planned for month 131 enters the forecast
#' model <- model_prophet(changepoints = 0,
#'                        events = list(campaign = c(campaigns, 131)),
#'                        steps = list(new_law = 81))
#' fit <- fit_model(model, ts(sales, frequency = 12))
#' round(fit$details$effects, 1)
#' @export
model_prophet <- function(changepoints = NULL, changepoint_range = NULL,
                          changepoint_prior_scale = NULL, seasonality_prior_scale = NULL,
                          fourier_order = NULL, event_prior_scale = NULL, events = NULL,
                          steps = NULL) {
  positions <- function(x, what) {
    if (is.null(x)) return(NULL)
    if (!is.list(x) || is.null(names(x)) || any(names(x) == "")) {
      abort("`", what, "` must be a named list.")
    }
    # positions count from 1 in R and from 0 on the other side
    lapply(x, function(p) check_counts(p, what, min = 1) - 1)
  }
  events <- positions(events, "events")
  steps <- positions(steps, "steps")
  if (!is.null(steps) && any(lengths(steps) != 1)) abort("each step has one position.")
  new_model("prophet",
            changepoints = check_count(changepoints, "changepoints", null = TRUE),
            changepoint_range = check_number(changepoint_range, "changepoint_range", null = TRUE),
            changepoint_prior_scale = check_number(changepoint_prior_scale,
                                                   "changepoint_prior_scale", null = TRUE),
            seasonality_prior_scale = check_number(seasonality_prior_scale,
                                                   "seasonality_prior_scale", null = TRUE),
            fourier_order = check_count(fourier_order, "fourier_order", min = 1, null = TRUE),
            event_prior_scale = check_number(event_prior_scale, "event_prior_scale", null = TRUE),
            events = events, steps = steps)
}

#' TBATS
#'
#' Trigonometric seasonality, Box-Cox transformation, ARMA errors, trend and
#' seasonal components (De Livera, Hyndman & Snyder, 2011). The seasonal
#' periods need not be whole numbers and there may be several. Whatever is
#' left as `NULL` is chosen by AIC. It is the slowest model of the package:
#' seconds for ten years of monthly data.
#'
#' @param periods Seasonal periods; by default the period of the series.
#' @param harmonics Harmonics of each period, in increasing order of period.
#' @param box_cox,trend,damped,arma_errors `TRUE`, `FALSE`, or `NULL` to
#'   choose.
#' @param arma_orders (p, q) of the ARMA errors, instead of choosing.
#' @inherit model_mean return
#' @family models
#' @examples
#' # a structure given in full fits at once; whatever is left out is chosen
#' model <- model_tbats(harmonics = 3, box_cox = FALSE, trend = TRUE, damped = FALSE,
#'                      arma_errors = FALSE)
#' fit <- fit_model(model, log(AirPassengers))
#' exp(predict(fit, 3))
#' @export
model_tbats <- function(periods = NULL, harmonics = NULL, box_cox = NULL, trend = NULL,
                        damped = NULL, arma_errors = NULL, arma_orders = NULL) {
  if (!is.null(periods)) {
    if (!is.numeric(periods) || any(!is.finite(periods)) || any(periods <= 1)) {
      abort("`periods` must be finite numbers above 1.")
    }
    periods <- as.numeric(periods)
  }
  new_model("tbats", periods = periods,
            harmonics = check_counts(harmonics, "harmonics", min = 1, max = 1000, null = TRUE),
            box_cox = check_flag(box_cox, "box_cox", null = TRUE),
            trend = check_flag(trend, "trend", null = TRUE),
            damped = check_flag(damped, "damped", null = TRUE),
            arma_errors = check_flag(arma_errors, "arma_errors", null = TRUE),
            arma_orders = check_counts(arma_orders, "arma_orders", n = 2, max = 50,
                                       null = TRUE))
}

#' Intermittent demand
#'
#' Croston's method (1972) and its variants for series where most periods
#' have no demand: `"sba"` (Syntetos & Boylan, 2005) removes Croston's upward
#' bias; `"tsb"` (Teunter, Syntetos & Babai, 2011) smooths the probability of
#' demand, so the rate falls while nothing is sold. The forecast is the same
#' for every horizon.
#'
#' @param variant `"croston"`, `"sba"` or `"tsb"`.
#' @param alpha Smoothing of the demand sizes and intervals (default 0.1).
#' @param beta Smoothing of the probability of demand, for TSB (default:
#'   `alpha`).
#' @param optimised Choose `alpha` by the squared error of the rate.
#' @inherit model_mean return
#' @family models
#' @examples
#' demand <- c(0, 0, 3, 0, 0, 0, 2, 0, 0, 4, 0, 0, 0, 0, 3, 0, 2, 0, 0, 0)
#' forecast_model(model_croston("sba"), demand, h = 3)
#' @export
model_croston <- function(variant = c("croston", "sba", "tsb"), alpha = NULL, beta = NULL,
                          optimised = FALSE) {
  new_model("croston", variant = match.arg(variant),
            alpha = check_number(alpha, "alpha", null = TRUE),
            beta = check_number(beta, "beta", null = TRUE),
            optimised = check_flag(optimised, "optimised"))
}

#' Forecast the seasonally adjusted series
#'
#' Decomposes the series by STL (or MSTL, for several periods), forecasts
#' the seasonally adjusted series with `model` and adds back the seasonal
#' pattern of the last cycle.
#'
#' @param model The model for the seasonally adjusted series.
#' @param periods Seasonal periods to take out; by default the period of the
#'   series.
#' @param robust Down-weight outliers in the decomposition.
#' @inherit model_mean return
#' @family models
#' @examples
#' forecast_model(model_log(model_decomposed(model_drift())), AirPassengers, h = 3)
#' @export
model_decomposed <- function(model, periods = NULL, robust = FALSE) {
  new_model("decomposed", model = check_model(model),
            periods = check_counts(periods, "periods", null = TRUE),
            robust = check_flag(robust, "robust"))
}

#' Several models combined
#'
#' The weights are learnt from the series itself: the last `origins`
#' periods are forecast by every member from the data before them, and the
#' errors decide how much each member counts. Then the members are fitted on
#' the whole series and their forecasts combined. As a candidate in a
#' [backtest()], an ensemble learns its weights again at every origin.
#'
#' @param members A list of models.
#' @param weighting `"inverse_error"` (in inverse proportion to the mean
#'   squared error), `"equal"`, `"median"` or `"stacked"` (the weights, none
#'   negative and adding up to one, with the smallest squared error).
#' @param origins Periods forecast to learn the weights (default 12).
#' @param horizon How far ahead those forecasts go (default: one seasonal
#'   cycle, at most 12).
#' @param top Keep only the members with the smallest error.
#' @inherit model_mean return
#' @family models
#' @examples
#' fit <- fit_model(model_ensemble(candidates_default(), top = 3), AirPassengers)
#' fit$params
#' @export
model_ensemble <- function(members, weighting = c("inverse_error", "equal", "median", "stacked"),
                           origins = NULL, horizon = NULL, top = NULL) {
  if (inherits(members, "foresight_model") || !is.list(members) || length(members) == 0) {
    abort("`members` must be a list of models.")
  }
  members <- lapply(members, check_model, what = "members")
  new_model("ensemble", members = unname(members), weighting = match.arg(weighting),
            origins = check_count(origins, "origins", min = 1, null = TRUE),
            horizon = check_count(horizon, "horizon", min = 1, null = TRUE),
            top = check_count(top, "top", min = 1, null = TRUE))
}

#' A model on the log or Box-Cox scale
#'
#' Runs `model` on the transformed series and brings the forecasts back to
#' the original scale. The series must be positive.
#'
#' @param model The model.
#' @param lambda The Box-Cox parameter (0 is the log), or `"guerrero"` to
#'   choose it at each fit by Guerrero's method.
#' @inherit model_mean return
#' @family models
#' @examples
#' forecast_model(model_log(model_airline()), AirPassengers, h = 3)
#' @export
model_box_cox <- function(model, lambda = 0) {
  if (!identical(lambda, "guerrero")) lambda <- check_number(lambda, "lambda")
  new_model("transformed", model = check_model(model), lambda = lambda)
}

#' @rdname model_box_cox
#' @export
model_log <- function(model) model_box_cox(model, 0)

#' Rename a model
#'
#' Sets the name (and description) under which a model appears in a
#' backtest or an ensemble.
#'
#' @param model A model.
#' @param name The new name.
#' @param description The new description; by default the model's own.
#' @return The model, renamed.
#' @examples
#' model <- with_name(model_seasonal_naive(), "same_month", "The same month of last year")
#' model
#' @export
with_name <- function(model, name, description = NULL) {
  check_model(model)
  if (!is.character(name) || length(name) != 1 || is.na(name) || !nzchar(name)) {
    abort("`name` must be a string.")
  }
  model$name <- name
  if (!is.null(description)) {
    if (!is.character(description) || length(description) != 1 || is.na(description)) {
      abort("`description` must be a string.")
    }
    model$description <- description
  }
  model
}

#' Name and description of a model
#'
#' @param model A model.
#' @return `model_name()`: the short name used in reports, such as
#'   `"log_arima_011_011"`; `model_description()`: one line about the method.
#' @export
#' @examples
#' model_name(model_log(model_airline()))
model_name <- function(model) rs_model_label(check_model(model))[1]

#' @rdname model_name
#' @export
model_description <- function(model) rs_model_label(check_model(model))[2]

#' @export
print.foresight_model <- function(x, ...) {
  label <- rs_model_label(x)
  cat("<foresight model> ", label[1], "\n", label[2], "\n", sep = "")
  invisible(x)
}

#' Ready sets of candidates
#'
#' `candidates_default()` has the benchmarks and every model that needs no
#' external data and fits in a moment: naive, drift, seasonal naive (plain
#' and with growth), Theta, Holt-Winters, log-linear regression, the airline
#' ARIMA and Prophet (each on the original and the log scale): 11 models.
#' `candidates_thorough()` adds two ensembles of those (inverse error and
#' stacked), ETS chosen automatically (alone, after STL, and after STL on the
#' log scale) and ARIMA with automatic orders (original and log): 18 models,
#' seconds rather than milliseconds in a backtest.
#'
#' @return A list of models.
#' @export
#' @examples
#' vapply(candidates_default(), model_name, "")
candidates_default <- function() {
  list(
    model_naive(), model_drift(), model_seasonal_naive(), model_seasonal_naive(growth = TRUE),
    model_theta(), model_holt_winters(), model_log_linear(), model_airline(),
    model_log(model_airline()), model_prophet(), model_log(model_prophet())
  )
}

#' @rdname candidates_default
#' @export
candidates_thorough <- function() {
  c(candidates_default(), list(
    model_ensemble(candidates_default()),
    model_ensemble(candidates_default(), weighting = "stacked"),
    model_auto_ets(),
    model_decomposed(model_auto_ets()),
    model_log(model_decomposed(model_auto_ets())),
    model_auto_arima(),
    model_log(model_auto_arima())
  ))
}
