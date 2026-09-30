# Seasonal ARIMA

ARIMA(p, d, q)(P, D, Q) estimated by exact Gaussian maximum likelihood
(the innovations algorithm), from three starting points.
`model_airline()` is ARIMA(0,1,1)(0,1,1), a good default for seasonal
series, usually on the log scale
([`model_log()`](https://strategicprojects.github.io/foresightr/reference/model_box_cox.md)).

## Usage

``` r
model_arima(
  order = c(0, 1, 1),
  seasonal = c(0, 0, 0),
  constant = NULL,
  regressors = NULL
)

model_airline()
```

## Arguments

- order:

  (p, d, q).

- seasonal:

  (P, D, Q), ignored for series without seasonality.

- constant:

  Estimate a mean (series not differenced) or a drift (one difference).
  By default only the mean is estimated.

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
[`model_auto_arima()`](https://strategicprojects.github.io/foresightr/reference/model_auto_arima.md),
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
fit <- fit_model(model_airline(), log(AirPassengers))
fit$details$seasonal_ma
#> [1] -0.5569353
```
