# Plot a backtest

The last years of the series and the forecast of the chosen candidate
with its widest interval.

## Usage

``` r
# S3 method for class 'foresight_backtest'
plot(x, candidate = x$best, history = 48, ...)
```

## Arguments

- x:

  A result of
  [`backtest()`](https://strategicprojects.github.io/foresightr/reference/backtest.md).

- candidate:

  A candidate name; by default the chosen one.

- history:

  How many of the last observations to show.

- ...:

  Passed to [`plot()`](https://rdrr.io/r/graphics/plot.default.html).

## Value

`x`, invisibly.
