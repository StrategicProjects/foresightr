# Decomposition and cleaning

``` r

library(foresightr)
```

## STL

[`decompose_stl()`](https://strategicprojects.github.io/foresightr/reference/decompose_stl.md)
splits a series into trend, seasonal pattern and remainder by LOESS. Its
defaults are those of [`stats::stl()`](https://rdrr.io/r/stats/stl.html)
and, without `robust`, so are its numbers.

``` r

d <- decompose_stl(log(AirPassengers), seasonal_window = 13)
d
#> <foresight decomposition> 144 observations, period 12
#> Strength of the trend: 0.996
#> Strength of seasonality (12): 0.961
autoplot(d)
```

![](cleaning_files/figure-html/unnamed-chunk-3-1.png)

The strengths, from 0 to 1, say how much of the variation the trend and
the seasonal pattern explain;
[`seasonal_strength()`](https://strategicprojects.github.io/foresightr/reference/kpss_statistic.md)
computes the latter directly. `robust = TRUE` down-weights outliers.

## Several seasonal periods

Daily data often has a weekly and a monthly pattern.
[`decompose_mstl()`](https://strategicprojects.github.io/foresightr/reference/decompose_stl.md)
estimates each in turn:

``` r

t <- 0:419
weekly <- c(5, 0, -2, -3, 0, 1, -1)
daily <- 100 + 0.05 * t + weekly[t %% 7 + 1] + 8 * sin(2 * pi * t / 30) +
  2 * sin(t * 1.7) * cos(t * 0.3)
d <- decompose_mstl(daily, periods = c(7, 30))
d$seasonal_strength
#>  seasonal_7 seasonal_30 
#>   0.8464823   0.9687255
autoplot(d)
```

![](cleaning_files/figure-html/unnamed-chunk-4-1.png)

The same decomposition serves to forecast:
[`model_decomposed()`](https://strategicprojects.github.io/foresightr/reference/model_decomposed.md)
runs any model on the seasonally adjusted series and adds the patterns
back.

``` r

model <- model_decomposed(model_drift(), periods = c(7, 30))
f <- forecast_model(model, daily, 14, period = 7)
round(f, 1)
#>  [1] 127.5 124.1 123.6 124.2 128.3 130.4 129.4 135.8 130.5 128.3 126.9 128.7
#> [13] 128.5 125.4
```

## Gaps and outliers

``` r

y <- log(AirPassengers)
y[30] <- y[30] + 0.8     # a typing error
y[100] <- y[100] - 0.7   # a strike
y[61:62] <- NA           # months never recorded
find_outliers(y)
#>   index     time    value replacement
#> 1    30 1951.417 5.981784    5.217194
#> 2    52 1953.250 5.459586    5.430423
#> 3   100 1957.250 5.152202    5.855171
#> 4   135 1960.167 6.037871    6.146164
```

[`fill_gaps()`](https://strategicprojects.github.io/foresightr/reference/fill_gaps.md)
fills the missing values following the seasonal pattern;
[`clean_series()`](https://strategicprojects.github.io/foresightr/reference/fill_gaps.md)
also replaces the outliers:

``` r

cleaned <- clean_series(y)
round(exp(cbind(dirty = y, clean = cleaned)[c(30, 61, 62, 100), ]))
#>      dirty clean
#> [1,]   396   184
#> [2,]    NA   207
#> [3,]    NA   199
#> [4,]   173   349
```

Models require complete series, so cleaning comes first when data has
gaps. Whether an outlier should be replaced is a judgement about the
data: a strike really happened, and removing it may hide a risk that
could happen again.
