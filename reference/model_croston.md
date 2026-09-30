# Intermittent demand

Croston's method (1972) and its variants for series where most periods
have no demand: `"sba"` (Syntetos & Boylan, 2005) removes Croston's
upward bias; `"tsb"` (Teunter, Syntetos & Babai, 2011) smooths the
probability of demand, so the rate falls while nothing is sold. The
forecast is the same for every horizon.

## Usage

``` r
model_croston(
  variant = c("croston", "sba", "tsb"),
  alpha = NULL,
  beta = NULL,
  optimised = FALSE
)
```

## Arguments

- variant:

  `"croston"`, `"sba"` or `"tsb"`.

- alpha:

  Smoothing of the demand sizes and intervals (default 0.1).

- beta:

  Smoothing of the probability of demand, for TSB (default: `alpha`).

- optimised:

  Choose `alpha` by the squared error of the rate.

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
demand <- c(0, 0, 3, 0, 0, 0, 2, 0, 0, 4, 0, 0, 0, 0, 3, 0, 2, 0, 0, 0)
forecast_model(model_croston("sba"), demand, h = 3)
#> [1] 0.8762393 0.8762393 0.8762393
```
