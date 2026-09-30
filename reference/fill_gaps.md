# Gaps and outliers

`fill_gaps()` fills missing values, following the seasonal pattern when
there is one. `find_outliers()` finds the observations far from what the
trend and the season suggest, and what they should rather be.
`clean_series()` does both.

## Usage

``` r
fill_gaps(y, period = NULL)

find_outliers(y, period = NULL)

clean_series(y, period = NULL)
```

## Arguments

- y:

  A `ts` or a numeric vector, possibly with `NA`.

- period:

  The seasonal period, when `y` is a plain vector.

## Value

`fill_gaps()` and `clean_series()`: the series, a `ts` when `y` is one.
`find_outliers()`: a data frame with the `index` (from 1), the `value`
and its `replacement`, plus the `time` for a `ts`.

## Examples

``` r
y <- log(AirPassengers)
y[c(30, 100)] <- y[c(30, 100)] + c(0.8, -0.7)
y[60] <- NA
find_outliers(y)
#>   index     time    value replacement
#> 1    30 1951.417 5.981784    5.224249
#> 2    52 1953.250 5.459586    5.428944
#> 3    62 1954.083 5.236442    5.304042
#> 4   100 1957.250 5.152202    5.853691
#> 5   135 1960.167 6.037871    6.140060
clean_series(y)[c(30, 60, 100)]
#> [1] 5.224249 5.300749 5.853691
```
