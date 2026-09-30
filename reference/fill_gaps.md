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
`find_outliers()`: a tibble with the `index` (from 1), the `value` and
its `replacement`, plus the `time` for a `ts` (a date for monthly and
quarterly data).

## Examples

``` r
y <- log(AirPassengers)
y[c(30, 100)] <- y[c(30, 100)] + c(0.8, -0.7)
y[60] <- NA
find_outliers(y)
#> # A tibble: 5 × 4
#>   index time       value replacement
#>   <int> <date>     <dbl>       <dbl>
#> 1    30 1951-06-01  5.98        5.22
#> 2    52 1953-04-01  5.46        5.43
#> 3    62 1954-02-01  5.24        5.30
#> 4   100 1957-04-01  5.15        5.85
#> 5   135 1960-03-01  6.04        6.14
clean_series(y)[c(30, 60, 100)]
#> [1] 5.224249 5.300749 5.853691
```
