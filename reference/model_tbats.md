# TBATS

Trigonometric seasonality, Box-Cox transformation, ARMA errors, trend
and seasonal components (De Livera, Hyndman & Snyder, 2011). The
seasonal periods need not be whole numbers and there may be several.
Whatever is left as `NULL` is chosen by AIC. It is the slowest model of
the package: seconds for ten years of monthly data.

## Usage

``` r
model_tbats(
  periods = NULL,
  harmonics = NULL,
  box_cox = NULL,
  trend = NULL,
  damped = NULL,
  arma_errors = NULL,
  arma_orders = NULL
)
```

## Arguments

- periods:

  Seasonal periods; by default the period of the series.

- harmonics:

  Harmonics of each period, in increasing order of period.

- box_cox, trend, damped, arma_errors:

  `TRUE`, `FALSE`, or `NULL` to choose.

- arma_orders:

  (p, q) of the ARMA errors, instead of choosing.

## Value

A model specification, to use with
[`fit_model()`](https://strategicprojects.github.io/foresightr/reference/fit_model.md),
[`forecast_model()`](https://strategicprojects.github.io/foresightr/reference/fit_model.md)
or
[`backtest()`](https://strategicprojects.github.io/foresightr/reference/backtest.md).

## See also

Other models:
[`model_arima()`](https://strategicprojects.github.io/foresightr/reference/model_arima.md),
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
[`model_theta()`](https://strategicprojects.github.io/foresightr/reference/model_theta.md)

## Examples

``` r
# a structure given in full fits at once; whatever is left out is chosen
model <- model_tbats(harmonics = 3, box_cox = FALSE, trend = TRUE, damped = FALSE,
                     arma_errors = FALSE)
fit <- fit_model(model, log(AirPassengers))
exp(predict(fit, 3))
#>           Jan      Feb      Mar
#> 1961 451.6791 469.9160 494.5989
```
