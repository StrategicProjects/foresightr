# Fit a model and forecast

`fit_model()` estimates a model on a series and keeps what was
estimated; predict() forecasts from it. `forecast_model()` does both in
one go.

## Usage

``` r
fit_model(model, y, period = NULL)

# S3 method for class 'foresight_fit'
predict(object, h = 12, ...)

forecast_model(model, y, h = 12, period = NULL)
```

## Arguments

- model:

  A model, e.g.
  [`model_theta()`](https://strategicprojects.github.io/foresightr/reference/model_theta.md).

- y:

  A `ts` or a numeric vector.

- period:

  The seasonal period when `y` is a plain vector (1 for none); a `ts`
  brings its own.

- object:

  A fit from `fit_model()`.

- h:

  Periods to forecast.

- ...:

  Not used.

## Value

`fit_model()`: an object of class `foresight_fit`, a list with the model
name and description, the estimated `params` (named numeric),
`log_likelihood`, `aic`, `aicc`, `bic` and `residuals` when the model
has them (`NA` otherwise), and `details`: orders and coefficients for
ARIMA, the code and smoothing for ETS, changepoints and event effects
for Prophet, the structure for TBATS. `forecast_model()`: the forecasts,
a `ts` when `y` is one.

## Details

The estimate lives in memory: a fit restored with
[`readRDS()`](https://rdrr.io/r/base/readRDS.html) cannot forecast and
has to be fitted again.

## Examples

``` r
fit <- fit_model(model_log(model_airline()), AirPassengers)
predict(fit, h = 12)
#>           Jan      Feb      Mar      Apr      May      Jun      Jul      Aug
#> 1961 450.4223 425.7170 479.0062 492.4044 509.0549 583.3447 670.0108 667.0775
#>           Sep      Oct      Nov      Dec
#> 1961 558.1891 497.2077 429.8718 477.2423
forecast_model(model_theta(), AirPassengers, h = 3)
#>           Jan      Feb      Mar
#> 1961 440.0767 428.3829 489.7055
```
