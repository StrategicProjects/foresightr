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

A one-row data frame: `periods`, `mean` and the bounds of each interval.
