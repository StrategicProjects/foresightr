# Several models combined

The weights are learnt from the series itself: the last `origins`
periods are forecast by every member from the data before them, and the
errors decide how much each member counts. Then the members are fitted
on the whole series and their forecasts combined. As a candidate in a
[`backtest()`](https://strategicprojects.github.io/foresightr/reference/backtest.md),
an ensemble learns its weights again at every origin.

## Usage

``` r
model_ensemble(
  members,
  weighting = c("inverse_error", "equal", "median", "stacked"),
  origins = NULL,
  horizon = NULL,
  top = NULL
)
```

## Arguments

- members:

  A list of models.

- weighting:

  `"inverse_error"` (in inverse proportion to the mean squared error),
  `"equal"`, `"median"` or `"stacked"` (the weights, none negative and
  adding up to one, with the smallest squared error).

- origins:

  Periods forecast to learn the weights (default 12).

- horizon:

  How far ahead those forecasts go (default: one seasonal cycle, at most
  12).

- top:

  Keep only the members with the smallest error.

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
[`model_ets()`](https://strategicprojects.github.io/foresightr/reference/model_ets.md),
[`model_holt_winters()`](https://strategicprojects.github.io/foresightr/reference/model_holt_winters.md),
[`model_log_linear()`](https://strategicprojects.github.io/foresightr/reference/model_log_linear.md),
[`model_mean()`](https://strategicprojects.github.io/foresightr/reference/model_mean.md),
[`model_prophet()`](https://strategicprojects.github.io/foresightr/reference/model_prophet.md),
[`model_tbats()`](https://strategicprojects.github.io/foresightr/reference/model_tbats.md),
[`model_theta()`](https://strategicprojects.github.io/foresightr/reference/model_theta.md)

## Examples

``` r
# \donttest{
fit <- fit_model(model_ensemble(candidates_default(), top = 3), AirPassengers)
fit$params
#>      weight_holt_winters        weight_log_linear weight_log_arima_011_011 
#>                0.4335252                0.3251547                0.2413201 
# }
```
