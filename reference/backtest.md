# Choose a model by what would have worked

Replays the past with each candidate: at each of the last `origins`
periods the model is fitted on the data before it and forecasts up to
`horizon` periods ahead. The candidates are ranked by the average error
(`metric`) over the horizons, the simple average of the best `combine`
is added as one more candidate, and every candidate forecasts from the
whole series with intervals taken from the errors it made: quantiles of
the relative error at each horizon, and of the relative error of totals
for the forecast of the next k periods together.

## Usage

``` r
backtest(
  y,
  candidates = candidates_default(),
  period = NULL,
  origins = 36,
  horizon = 12,
  min_train = 48,
  window = NULL,
  combine = 2,
  levels = c(0.8, 0.95),
  metric = c("mape", "mae", "rmse", "mase"),
  parallel = TRUE
)
```

## Arguments

- y:

  A `ts` or a numeric vector.

- candidates:

  A list of models; see
  [`candidates_default()`](https://strategicprojects.github.io/foresightr/reference/candidates_default.md).

- period:

  The seasonal period when `y` is a plain vector.

- origins:

  Forecast origins, the last periods of the series.

- horizon:

  Longest horizon forecast and evaluated.

- min_train:

  Observations to train at the first origin; shorter series get fewer
  origins.

- window:

  Train on the last `window` observations only (default: everything
  before the origin).

- combine:

  Also evaluate the average of the best `combine` models (fewer than 2
  disables it).

- levels:

  Coverage of the intervals.

- metric:

  `"mape"`, `"mae"`, `"rmse"` or `"mase"`.

- parallel:

  Fit the origins on all cores. The result is the same either way.

## Value

An object of class `foresight_backtest`, a list with

- `ranking`: one row per candidate with its `score`, whether it was
  `chosen`, the models involved and a description;

- `best`: the name of the chosen candidate;

- `forecast`: the forecast of the chosen candidate with its intervals;

- `candidates`: for each candidate, its `accuracy` by horizon (pairs
  evaluated, MAPE, bias, MAE, RMSE, MASE), the relative error `bands`,
  the `forecast`, the `cumulative` forecast of totals, the
  `trajectories` of the backtest (origins by horizons) and the fitted
  `params`;

- `origins`, `first_origin` (position of the first period forecast),
  `horizon`, `metric` and `levels`.

## Examples

``` r
# \donttest{
bt <- backtest(AirPassengers, origins = 24)
bt
#> <foresight backtest> 12 candidates, 24 origins, 12 periods ahead
#> Chosen: mean(log_linear+log_arima_011_011) (MAPE 2.259)
#> 
#>                                  name  score
#> 1  mean(log_linear+log_arima_011_011)  2.259
#> 2                          log_linear  3.292
#> 3                   log_arima_011_011  3.380
#> 4                        holt_winters  3.698
#> 5                       arima_011_011  4.140
#> 6               seasonal_naive_growth  5.385
#> 7                         log_prophet  5.729
#> 8                             prophet  6.128
#> 9                               theta  6.242
#> 10                     seasonal_naive 10.793
#> ... and 2 more
bt$forecast
#>    horizon     time     mean lower_80 upper_80 lower_95 upper_95
#> 1        1 1961.000 451.1629 435.5788 459.4081 420.0576 469.5416
#> 2        2 1961.083 428.1173 417.0759 436.6258 399.5738 442.3360
#> 3        3 1961.167 485.8424 475.9508 492.8912 453.1669 494.5819
#> 4        4 1961.250 492.6722 480.0743 501.4043 461.2832 508.0285
#> 5        5 1961.333 507.8313 495.8102 515.9807 473.7930 520.5540
#> 6        6 1961.417 586.5683 569.3894 596.4046 546.8936 601.9106
#> 7        7 1961.500 669.8282 649.0314 689.1857 620.1254 695.6713
#> 8        8 1961.583 666.0720 642.9016 675.4146 617.8694 688.3249
#> 9        9 1961.667 561.9431 541.8380 572.2993 521.2817 574.8883
#> 10      10 1961.750 497.1960 477.4047 510.4216 456.5302 511.7094
#> 11      11 1961.833 431.5305 411.4508 444.1681 397.7149 447.2060
#> 12      12 1961.917 481.0408 457.4564 492.6139 443.9095 498.7222
total_forecast(bt, 6)
#>   periods     mean lower_80 upper_80 lower_95 upper_95
#> 1       6 2952.194 2891.163 2956.663 2880.515 3005.726
# }
```
