# Accuracy of forecasts

`mape()` is the mean absolute percentage error and `pct_bias()` the mean
of (forecast - actual) / actual, both in percent; `mae()` and `rmse()`
are the mean absolute and root mean squared errors; `mase()` scales the
mean absolute error by the in-sample error of the seasonal naive
forecast on `train` (Hyndman & Koehler, 2006).

## Usage

``` r
mape(actual, forecast)

pct_bias(actual, forecast)

mae(actual, forecast)

rmse(actual, forecast)

mase(actual, forecast, train, period = 1)
```

## Arguments

- actual, forecast:

  Numeric vectors of the same length.

- train:

  The history the forecasts were made from, for `mase()`.

- period:

  Its seasonal period.

## Value

A number (`NA` when it cannot be computed).

## Examples

``` r
mape(c(100, 200), c(110, 180))
#> [1] 10
```
