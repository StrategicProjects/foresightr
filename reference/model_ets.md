# Exponential smoothing

A member of the exponential smoothing family in state space form
(Hyndman et al., 2008), by its code: error (`A`, `M`), trend (`N`, `A`,
`Ad`) and season (`N`, `A`, `M`), such as `"MAM"` or `"AAdN"`.
`model_auto_ets()` chooses the member with the best criterion;
multiplicative parts only for positive series.

## Usage

``` r
model_ets(code)

model_auto_ets(criterion = c("aicc", "aic", "bic"))
```

## Arguments

- code:

  The model, e.g. `"MAM"`.

- criterion:

  `"aicc"`, `"aic"` or `"bic"`.

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
[`model_holt_winters()`](https://strategicprojects.github.io/foresightr/reference/model_holt_winters.md),
[`model_log_linear()`](https://strategicprojects.github.io/foresightr/reference/model_log_linear.md),
[`model_mean()`](https://strategicprojects.github.io/foresightr/reference/model_mean.md),
[`model_prophet()`](https://strategicprojects.github.io/foresightr/reference/model_prophet.md),
[`model_tbats()`](https://strategicprojects.github.io/foresightr/reference/model_tbats.md),
[`model_theta()`](https://strategicprojects.github.io/foresightr/reference/model_theta.md)

## Examples

``` r
fit <- fit_model(model_auto_ets(), AirPassengers)
fit$details$code
#> [1] "MAM"
```
