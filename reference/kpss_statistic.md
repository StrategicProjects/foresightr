# Tests and transformations

- `kpss_statistic()`: the KPSS statistic for level stationarity
  (Kwiatkowski et al., 1992); above 0.463 a difference is called for at
  5%.

- `n_differences()`: differences needed by repeated KPSS tests.

- `n_seasonal_differences()`: seasonal differences needed, by the
  strength of seasonality.

- `seasonal_strength()`: from 0 to 1 (Wang, Smith & Hyndman, 2006).

- `autocorrelations()`: at lags 1 to `max_lag`.

- `box_cox()`, `inv_box_cox()`: the transformation and its inverse;
  `guerrero_lambda()` chooses lambda by Guerrero's method (1993).

## Usage

``` r
kpss_statistic(y)

n_differences(y, max = 2)

n_seasonal_differences(y, period = NULL)

seasonal_strength(y, period = NULL)

autocorrelations(y, max_lag)

box_cox(x, lambda)

inv_box_cox(x, lambda)

guerrero_lambda(y, period = NULL)
```

## Arguments

- y, x:

  A `ts` or a numeric vector.

- max:

  Most differences.

- period:

  The seasonal period, when `y` is a plain vector.

- max_lag:

  Largest lag.

- lambda:

  The Box-Cox parameter; 0 is the log.

## Value

A number, or the transformed values.

## Examples

``` r
kpss_statistic(log(AirPassengers))
#> [1] 4.540882
n_differences(log(AirPassengers))
#> [1] 1
guerrero_lambda(AirPassengers)
#> [1] -0.2947236
```
