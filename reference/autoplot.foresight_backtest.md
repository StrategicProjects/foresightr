# Charts of a backtest or a decomposition

[`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
draws, with ggplot2:

## Usage

``` r
# S3 method for class 'foresight_backtest'
autoplot(
  object,
  type = c("forecast", "accuracy", "ranking"),
  candidate = object$best,
  history = 48,
  top = 4,
  ...
)

# S3 method for class 'foresight_backtest'
plot(
  x,
  type = c("forecast", "accuracy", "ranking"),
  candidate = x$best,
  history = 48,
  top = 4,
  ...
)

# S3 method for class 'foresight_decomposition'
autoplot(object, ...)

# S3 method for class 'foresight_decomposition'
plot(x, ...)
```

## Arguments

- object, x:

  A result of
  [`backtest()`](https://strategicprojects.github.io/foresightr/reference/backtest.md)
  or of
  [`decompose_stl()`](https://strategicprojects.github.io/foresightr/reference/decompose_stl.md)
  /
  [`decompose_mstl()`](https://strategicprojects.github.io/foresightr/reference/decompose_stl.md).

- type:

  What to draw.

- candidate:

  A candidate name, for `type = "forecast"`; by default the chosen one.

- history:

  How many of the last observations to show.

- top:

  How many of the best candidates, for `type = "accuracy"`: at most 4,
  so that they can be told apart.

- ...:

  Not used.

## Value

A ggplot object.

## Details

- `type = "forecast"`: the last observations and the forecast of a
  candidate with its empirical intervals;

- `type = "accuracy"`: the error of the best candidates by horizon;

- `type = "ranking"`: every candidate by its score, the chosen one
  highlighted;

and, for a decomposition, the series, the trend, each seasonal pattern
and the remainder.
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) draws the same
chart. Both return a ggplot object, which can be themed and annotated
further.

## Examples

``` r
bt <- backtest(AirPassengers, origins = 24)
autoplot(bt)

autoplot(bt, "accuracy")

autoplot(decompose_stl(log(AirPassengers), seasonal_window = 13))
```
