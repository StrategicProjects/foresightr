# External variables for a regression with ARIMA errors

`fourier_terms()` gives the sine and cosine pairs of a seasonal period
up to `order` harmonics; `seasonal_dummies()` one dummy per season but
the first. Both have `rows` rows, which must cover the series and the
horizon to be forecast. Combine them, or add your own columns, with
[`cbind()`](https://rdrr.io/r/base/cbind.html).

## Usage

``` r
fourier_terms(period, order, rows)

seasonal_dummies(period, rows)
```

## Arguments

- period:

  The seasonal period (need not be a whole number for Fourier terms).

- order:

  Harmonics.

- rows:

  Rows: the length of the series plus the horizon.

## Value

A data frame.

## Examples

``` r
x <- fourier_terms(12, 3, length(AirPassengers) + 12)
fit <- fit_model(model_arima(c(1, 1, 1), constant = TRUE, regressors = x), log(AirPassengers))
predict(fit, 12)
#>           Jan      Feb      Mar      Apr      May      Jun      Jul      Aug
#> 1961 6.111487 6.158341 6.212377 6.239372 6.260181 6.351994 6.483706 6.501204
#>           Sep      Oct      Nov      Dec
#> 1961 6.353833 6.188675 6.142377 6.182586
```
