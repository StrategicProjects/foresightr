# The backtest and its intervals

``` r

library(foresightr)
data <- read.csv(system.file("extdata", "piaui_revenue.csv", package = "foresightr"),
                 comment.char = "#")
fpe <- ts(data$fpe / 1e6, start = c(2017, 3), frequency = 12)  # BRL million
```

## Replaying the past

A rolling-origin backtest stands at each of the last `origins` periods
of the series, fits every candidate on the data before that point only,
and forecasts up to `horizon` periods ahead. Each forecast is compared
with what actually happened. Nothing a model sees at an origin comes
from after it.

``` r

bt <- backtest(fpe, origins = 36, horizon = 12)
bt$origins
#> [1] 36
bt$first_origin   # position of the first period forecast
#> [1] 77
```

Series shorter than `min_train` plus the origins get fewer origins;
`window` trains on the last observations only, for series whose
behaviour changed.

## The error by horizon

Errors grow with the horizon. Each candidate keeps them one horizon at a
time: the pairs evaluated, the mean absolute percentage error, the bias
(positive when forecasts ran high), MAE, RMSE and MASE.

``` r

acc <- bt$candidates[[bt$best]]$accuracy
acc[c(1, 3, 6, 12), ]
#>    horizon  n     mape          bias      mae     rmse      mase
#> 1        1 36 5.218180  0.4834240850 34.97901 44.61399 0.5426601
#> 3        3 34 5.266489 -0.0008762147 36.77655 45.48067 0.5716142
#> 6        6 31 4.709801 -0.5143452008 34.38851 43.18587 0.5344773
#> 12      12 25 5.069807 -0.4405582622 34.28807 40.99345 0.5336450
```

The ranking averages the chosen `metric` over the horizons. The last
candidate is the simple average of the best `combine` models, often
better than either:

``` r

bt$ranking[order(bt$ranking$score), c("name", "score")][1:5, ]
#>                                     name    score
#> 12 mean(log_arima_011_011+arima_011_011) 5.201558
#> 9                      log_arima_011_011 5.272317
#> 8                          arima_011_011 5.607081
#> 4                  seasonal_naive_growth 5.833625
#> 11                           log_prophet 6.111936
```

Changing the metric changes the ranking only when models trade accuracy
in different ways; `"mase"` scales the errors by the seasonal naive
error of each training set, which makes series of different sizes
comparable.

## Intervals from the errors actually made

An interval here is not derived from a distribution. At each horizon,
the backtest collects the relative errors `actual / forecast - 1` of the
candidate and takes their quantiles: the 80% interval goes from the 10%
to the 90% quantile. The bands are kept in relative terms and applied to
the final forecast.

``` r

bt$candidates[[bt$best]]$bands[c(1, 6, 12), ]
#>    horizon    lower_80   upper_80    lower_95  upper_95
#> 1        1 -0.08813160 0.07495426 -0.13956212 0.1102469
#> 6        6 -0.06366508 0.08119672 -0.08318208 0.1324175
#> 12      12 -0.06836198 0.08381365 -0.09594299 0.1382616
bt$forecast[c(1, 6, 12), ]
#>    horizon     time      mean lower_80  upper_80 lower_95 upper_95
#> 1        1 2026.500  623.6271 568.6658  670.3706 536.5924  692.380
#> 6        6 2026.917  995.0369 931.6878 1075.8306 912.2676 1126.797
#> 12      12 2027.417 1036.9406 966.0533 1123.8504 937.4534 1180.310
```

With 36 origins, the 95% bounds rest on few errors at long horizons;
they are honest about the past but not smooth. More origins give
steadier bands, at the cost of judging models on older data.

The trajectories of the backtest are kept, one row per origin, should
you want another summary of them:

``` r

dim(bt$candidates[[bt$best]]$trajectories)
#> [1] 36 12
```

## Totals

Budgets are about totals: the revenue of the rest of the year, not of
each month. The backtest also measures the error of the sum of the first
k periods, so the total gets its own interval:

``` r

total_forecast(bt, 6)
#>   periods     mean lower_80 upper_80 lower_95 upper_95
#> 1       6 4631.779 4486.398 4910.636 4271.149 4923.313
```

Adding up the six monthly bounds would overstate the uncertainty:
monthly errors partly cancel in a sum.

``` r

colSums(bt$forecast[1:6, c("mean", "lower_80", "upper_80")])
#>     mean lower_80 upper_80 
#> 4631.779 4302.830 5000.857
```

## Looking at it

``` r

plot(bt)
```

![](backtest_files/figure-html/unnamed-chunk-10-1.png)

Any candidate can be plotted or inspected by name:

``` r

plot(bt, candidate = "seasonal_naive")
```

![](backtest_files/figure-html/unnamed-chunk-11-1.png)
