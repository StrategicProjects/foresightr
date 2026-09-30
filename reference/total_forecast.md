# Forecast of a total

The forecast of the sum of the next `k` periods, with intervals measured
on totals in the backtest. Adding up the limits of each period would
overstate the uncertainty of a total.

## Usage

``` r
total_forecast(backtest, k, candidate = backtest$best)
```

## Arguments

- backtest:

  A result of
  [`backtest()`](https://strategicprojects.github.io/foresightr/reference/backtest.md).

- k:

  Periods added up.

- candidate:

  A candidate name; by default the chosen one.

## Value

A one-row tibble: `periods`, `mean` and the bounds of each interval.

## Examples

``` r
bt <- backtest(AirPassengers, list(model_theta(), model_seasonal_naive()), origins = 24)
total_forecast(bt, 6)
#> # A tibble: 1 × 6
#>   periods  mean lower_80 upper_80 lower_95 upper_95
#>     <int> <dbl>    <dbl>    <dbl>    <dbl>    <dbl>
#> 1       6 2859.    2847.    3118.    2788.    3252.
colSums(bt$forecast[1:6, c("mean", "lower_80", "upper_80")])  # wider, and wrong
#>     mean lower_80 upper_80 
#> 2858.902 2762.949 3155.645 
```
