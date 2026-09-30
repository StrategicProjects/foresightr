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

  A list of models with distinct names (see
  [`with_name()`](https://strategicprojects.github.io/foresightr/reference/with_name.md));
  by default
  [`candidates_default()`](https://strategicprojects.github.io/foresightr/reference/candidates_default.md).
  A candidate that cannot forecast at every origin and from the whole
  series is left out, with a warning.

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

  Train on the last `window` observations only, at every origin and for
  the final forecast (default: everything before the origin).

- combine:

  Also evaluate the average of the best `combine` models (fewer than 2,
  or more than the candidates left, disables it).

- levels:

  Coverage of the intervals, each above 0 and below 1.

- metric:

  `"mape"`, `"mae"`, `"rmse"` or `"mase"`.

- parallel:

  Fit the origins on several threads: all cores, or as many as
  [`foresight_threads()`](https://strategicprojects.github.io/foresightr/reference/foresight_threads.md)
  allows. The result is the same either way.

## Value

An object of class `foresight_backtest`, a list whose tables are
tibbles:

- `ranking`: one row per candidate that went through the backtest, with
  its `score`, whether it was `chosen`, the models involved and a
  description; `dropped` names those left out;

- `best`: the name of the chosen candidate;

- `forecast`: the forecast of the chosen candidate with its intervals,
  and the `time` of each period for a `ts` (a date for monthly and
  quarterly data);

- `candidates`: for each candidate, its `accuracy` by horizon (pairs
  evaluated, MAPE, bias, MAE, RMSE, MASE), the relative error `bands`,
  the `forecast`, the `cumulative` forecast of totals, the
  `trajectories` of the backtest (origins by horizons) and the fitted
  `params`; an interval is `NA` at a horizon where every forecast of the
  backtest was zero;

- `origins`, `first_origin` (position of the first period forecast),
  `horizon`, `metric` and `levels`.

## Examples

``` r
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
#> # A tibble: 12 × 7
#>    horizon time        mean lower_80 upper_80 lower_95 upper_95
#>      <int> <date>     <dbl>    <dbl>    <dbl>    <dbl>    <dbl>
#>  1       1 1961-01-01  451.     436.     459.     420.     470.
#>  2       2 1961-02-01  428.     417.     437.     400.     442.
#>  3       3 1961-03-01  486.     476.     493.     453.     495.
#>  4       4 1961-04-01  493.     480.     501.     461.     508.
#>  5       5 1961-05-01  508.     496.     516.     474.     521.
#>  6       6 1961-06-01  587.     569.     596.     547.     602.
#>  7       7 1961-07-01  670.     649.     689.     620.     696.
#>  8       8 1961-08-01  666.     643.     675.     618.     688.
#>  9       9 1961-09-01  562.     542.     572.     521.     575.
#> 10      10 1961-10-01  497.     477.     510.     457.     512.
#> 11      11 1961-11-01  432.     411.     444.     398.     447.
#> 12      12 1961-12-01  481.     457.     493.     444.     499.
total_forecast(bt, 6)
#> # A tibble: 1 × 6
#>   periods  mean lower_80 upper_80 lower_95 upper_95
#>     <int> <dbl>    <dbl>    <dbl>    <dbl>    <dbl>
#> 1       6 2952.    2891.    2957.    2881.    3006.
```
