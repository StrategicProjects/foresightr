# ARIMA with automatic orders

Differences chosen by the KPSS test and by the strength of seasonality,
orders by a stepwise search on the information criterion (Hyndman &
Khandakar, 2008). In a backtest the choice is made again at every
origin, so the whole procedure is judged, not one lucky specification.

## Usage

``` r
model_auto_arima(
  criterion = c("aicc", "aic", "bic"),
  d = NULL,
  seasonal_d = NULL,
  max_order = c(5, 5, 2, 2),
  regressors = NULL
)
```

## Arguments

- criterion:

  `"aicc"`, `"aic"` or `"bic"`.

- d, seasonal_d:

  Fix the number of differences instead of testing.

- max_order:

  Largest p, q, P and Q.

- regressors:

  External variables, a data frame, matrix or named list of numeric
  columns with one row per period from the first observation on; to
  forecast, the rows must also cover the horizon. The model becomes a
  regression with ARIMA errors. See
  [`fourier_terms()`](https://strategicprojects.github.io/foresightr/reference/fourier_terms.md).

## Value

A model specification, to use with
[`fit_model()`](https://strategicprojects.github.io/foresightr/reference/fit_model.md),
[`forecast_model()`](https://strategicprojects.github.io/foresightr/reference/fit_model.md)
or
[`backtest()`](https://strategicprojects.github.io/foresightr/reference/backtest.md).

## See also

Other models:
[`model_arima()`](https://strategicprojects.github.io/foresightr/reference/model_arima.md),
[`model_box_cox()`](https://strategicprojects.github.io/foresightr/reference/model_box_cox.md),
[`model_croston()`](https://strategicprojects.github.io/foresightr/reference/model_croston.md),
[`model_decomposed()`](https://strategicprojects.github.io/foresightr/reference/model_decomposed.md),
[`model_ensemble()`](https://strategicprojects.github.io/foresightr/reference/model_ensemble.md),
[`model_ets()`](https://strategicprojects.github.io/foresightr/reference/model_ets.md),
[`model_holt_winters()`](https://strategicprojects.github.io/foresightr/reference/model_holt_winters.md),
[`model_log_linear()`](https://strategicprojects.github.io/foresightr/reference/model_log_linear.md),
[`model_mean()`](https://strategicprojects.github.io/foresightr/reference/model_mean.md),
[`model_prophet()`](https://strategicprojects.github.io/foresightr/reference/model_prophet.md),
[`model_tbats()`](https://strategicprojects.github.io/foresightr/reference/model_tbats.md),
[`model_theta()`](https://strategicprojects.github.io/foresightr/reference/model_theta.md)

## Examples

``` r
fit <- fit_model(model_auto_arima(), log(AirPassengers))
fit$details$order
#> [1] 0 1 1
fit$details$seasonal_order
#> [1] 0 1 1
```
