# Prophet-style trend with changepoints and events

The model of Taylor & Letham (2018) fitted without Stan: a piecewise
linear trend whose changes of slope are shrunk by a Laplace prior (those
that do not matter come out as exactly zero), Fourier seasonality, and
optional events and lasting steps.

## Usage

``` r
model_prophet(
  changepoints = NULL,
  changepoint_range = NULL,
  changepoint_prior_scale = NULL,
  seasonality_prior_scale = NULL,
  fourier_order = NULL,
  event_prior_scale = NULL,
  events = NULL,
  steps = NULL
)
```

## Arguments

- changepoints:

  Potential changepoints (default 25).

- changepoint_range:

  Share of the history where they may fall (default 0.8).

- changepoint_prior_scale, seasonality_prior_scale, event_prior_scale:

  Scales of the priors (defaults 0.05, 10 and 10).

- fourier_order:

  Harmonics of the seasonal pattern (default: 10 for yearly patterns, at
  most half the period).

- events:

  Named list: for each event, the positions where it happens, counted
  from 1 at the first observation, future ones included.

- steps:

  Named list: for each lasting change of level, the position from which
  it applies.

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
[`model_tbats()`](https://strategicprojects.github.io/foresightr/reference/model_tbats.md),
[`model_theta()`](https://strategicprojects.github.io/foresightr/reference/model_theta.md)
