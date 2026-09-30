# Regressors and events

``` r

library(foresightr)
path <- system.file("extdata", "piaui_revenue.csv", package = "foresightr")
data <- read.csv(path, comment.char = "#")
icms <- ts(data$icms / 1e6, start = c(2017, 3), frequency = 12)
```

External information enters a model in three ways: as regressors of an
ARIMA model, as a price index that deflates a log-linear regression, and
as dated events of a Prophet-style model. In every case its values must
also cover the periods to be forecast.

## Regression with ARIMA errors

Tax revenue follows prices. With the log of a price index as a
regressor, the errors of the regression follow an ARIMA model, and both
are estimated together. Here the model is fitted on the first 100
months, so that the index covers the 12 months forecast.

``` r

model <- model_arima(c(0, 1, 1), c(0, 1, 1),
                     regressors = data.frame(ipca = log(data$ipca_index)))
fit <- fit_model(model, log(window(icms, end = time(icms)[100])))
fit$details$regression
#>     ipca 
#> 3.630129
exp(predict(fit, 6))
#>           Jul      Aug      Sep      Oct      Nov      Dec
#> 2025 755.1627 755.8939 770.2862 789.3318 772.8459 800.0233
```

The same `regressors` argument is taken by
[`model_arima()`](https://strategicprojects.github.io/foresightr/reference/model_arima.md)
and
[`model_auto_arima()`](https://strategicprojects.github.io/foresightr/reference/model_auto_arima.md),
as a data frame, a matrix or a named list with one row per period from
the first observation on.

## Fourier terms

Sine and cosine pairs describe a seasonal pattern with few parameters,
and the period need not be a whole number.
[`fourier_terms()`](https://strategicprojects.github.io/foresightr/reference/fourier_terms.md)
gives them for as many rows as needed:

``` r

y <- log(AirPassengers)
x <- fourier_terms(12, 3, length(y) + 12)
fit <- fit_model(model_arima(c(1, 1, 1), constant = TRUE, regressors = x), y)
names(fit$details$regression)
#> [1] "sin1_12" "cos1_12" "sin2_12" "cos2_12" "sin3_12" "cos3_12"
round(exp(predict(fit, 12)))
#>      Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
#> 1961 451 473 499 513 523 574 654 666 575 487 465 484
```

[`seasonal_dummies()`](https://strategicprojects.github.io/foresightr/reference/fourier_terms.md)
gives one dummy per season instead; combine sets of regressors with
[`cbind()`](https://rdrr.io/r/base/cbind.html).

## A deflated regression

`model_log_linear(deflator = )` fits trend and seasonality on the
deflated series and inflates the forecasts back, with the index covering
the horizon:

``` r

first_100 <- window(icms, end = time(icms)[100])
deflated <- model_log_linear(deflator = data$ipca_index[1:112])
forecast_model(deflated, first_100, 12)
#>           Jan      Feb      Mar      Apr      May      Jun      Jul      Aug
#> 2025                                                       723.0007 735.2485
#> 2026 800.9495 708.6957 651.4263 688.2408 684.8211 778.6687                  
#>           Sep      Oct      Nov      Dec
#> 2025 748.6750 754.8139 770.6882 768.7912
#> 2026
```

## Events and steps

A Prophet-style model takes events, which happen at given positions
(counted from 1 at the first observation, future ones included), and
steps, lasting changes of level from a position on. Their effects are
estimated with the trend and seasonality.

``` r

set.seed(1)
t <- 1:120
sales <- 200 + 0.8 * t + 5 * sin(2 * pi * t / 12) + rnorm(120, sd = 2)
campaigns <- c(11, 35, 59, 83, 107)
sales[campaigns] <- sales[campaigns] + 20     # a campaign every other November
sales[t >= 81] <- sales[t >= 81] - 15          # a new law cuts the level
sales <- ts(sales, frequency = 12)

model <- model_prophet(changepoints = 0,
                       events = list(campaign = c(campaigns, 131)),
                       steps = list(new_law = 81))
fit <- fit_model(model, sales)
round(fit$details$effects, 1)
#> campaign  new_law 
#>     19.8    -14.8
```

The effects come out close to the +20 and -15 put in, and the forecast
includes the campaign planned for position 131.
