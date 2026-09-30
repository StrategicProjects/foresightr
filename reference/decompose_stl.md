# Decompose a series by STL or MSTL

`decompose_stl()` splits a series into trend, seasonal pattern and
remainder by LOESS (Cleveland, Cleveland, McRae & Terpenning, 1990); its
defaults are those of [`stats::stl()`](https://rdrr.io/r/stats/stl.html)
and, without `robust`, so are its numbers (with `robust = TRUE` the two
agree up to the eleventh robustness round and drift apart in the third
digit after that). `decompose_mstl()` applies STL in turn to each of
several seasonal periods (Bandara, Hyndman & Bergmeir, 2021).

## Usage

``` r
decompose_stl(
  y,
  period = NULL,
  seasonal_window = NULL,
  trend_window = NULL,
  low_pass_window = NULL,
  degrees = NULL,
  robust = FALSE,
  inner = NULL,
  outer = NULL
)

decompose_mstl(
  y,
  periods = NULL,
  windows = NULL,
  iterations = NULL,
  robust = FALSE
)
```

## Arguments

- y:

  A `ts` or a numeric vector, longer than two full cycles.

- period:

  The seasonal period, when `y` is a plain vector.

- seasonal_window:

  The LOESS window over the cycles, an odd number, usually 7 or more (an
  even number is taken as the next odd one): the smaller, the faster the
  pattern may change. `NULL` keeps the same pattern in every cycle
  (`s.window = "periodic"`).

- trend_window, low_pass_window:

  LOESS windows of the trend and of the low-pass filter.

- degrees:

  LOESS degrees (0 or 1) of the seasonal, trend and low-pass smoothers;
  default `c(0, 1, 1)`.

- robust:

  Down-weight outliers.

- inner, outer:

  Passes of the inner loop and robustness rounds.

- periods:

  Seasonal periods.

- windows:

  Seasonal windows, one per period in increasing order of period
  (default 11, 15, 19, ...).

- iterations:

  Rounds over the periods (default 2).

## Value

An object of class `foresight_decomposition`, a list with `trend`,
`seasonal` (a matrix, one column per period), `remainder`,
`seasonally_adjusted`, `periods`, `trend_strength` and
`seasonal_strength` (from 0 to 1; Wang, Smith & Hyndman, 2006).

## Examples

``` r
d <- decompose_stl(log(AirPassengers), seasonal_window = 13)
d$seasonal_strength
#> seasonal_12 
#>    0.961261 
plot(d)
```
