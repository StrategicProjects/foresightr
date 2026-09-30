# The models

``` r

library(foresightr)
y <- AirPassengers
```

Every model is a specification: a small list that says what to fit. It
can be printed, saved, renamed and combined; it is estimated only by
[`fit_model()`](https://strategicprojects.github.io/foresightr/reference/fit_model.md),
[`forecast_model()`](https://strategicprojects.github.io/foresightr/reference/fit_model.md)
or inside a
[`backtest()`](https://strategicprojects.github.io/foresightr/reference/backtest.md).

``` r

model_log(model_airline())
#> <foresight model> log_arima_011_011
#> ARIMA(0,1,1)(0,1,1) by exact maximum likelihood, on the log scale
```

## Yardsticks

[`model_naive()`](https://strategicprojects.github.io/foresightr/reference/model_mean.md),
[`model_drift()`](https://strategicprojects.github.io/foresightr/reference/model_mean.md),
[`model_mean()`](https://strategicprojects.github.io/foresightr/reference/model_mean.md)
and
[`model_seasonal_naive()`](https://strategicprojects.github.io/foresightr/reference/model_mean.md)
are what any other model must beat. The seasonal naive forecast with
`growth = TRUE` repeats last year scaled by the growth of the last
twelve months, a strong benchmark for revenue.

``` r

forecast_model(model_seasonal_naive(growth = TRUE), y, 6)
#>           Jan      Feb      Mar      Apr      May      Jun
#> 1961 463.5677 434.6642 465.7911 512.4813 524.7097 594.7451
```

## Theta and Holt-Winters

[`model_theta()`](https://strategicprojects.github.io/foresightr/reference/model_theta.md)
is the method that won the M3 competition, equivalent to simple
exponential smoothing with drift, on the seasonally adjusted series.
[`model_holt_winters()`](https://strategicprojects.github.io/foresightr/reference/model_holt_winters.md)
smooths level, trend and a multiplicative seasonal pattern.

``` r

fit_model(model_holt_winters(), y)$params
#>        alpha         beta        gamma          phi sse_relative 
#>    0.3000000    0.0200000    0.8000000    1.0000000    0.2195894
```

## Exponential smoothing

[`model_ets()`](https://strategicprojects.github.io/foresightr/reference/model_ets.md)
fits one member of the family by its code (error, trend, season);
[`model_auto_ets()`](https://strategicprojects.github.io/foresightr/reference/model_ets.md)
chooses by AICc among those that suit the series.

``` r

fit <- fit_model(model_auto_ets(), y)
fit$details$code
#> [1] "MAM"
fit$details[c("alpha", "beta", "gamma")]
#> $alpha
#> [1] 0.7409353
#> 
#> $beta
#> [1] 1e-04
#> 
#> $gamma
#> [1] 1e-04
```

## ARIMA

[`model_arima()`](https://strategicprojects.github.io/foresightr/reference/model_arima.md)
is estimated by exact maximum likelihood.
[`model_auto_arima()`](https://strategicprojects.github.io/foresightr/reference/model_auto_arima.md)
chooses the differences by tests and the orders by a stepwise search.

``` r

fit <- fit_model(model_auto_arima(), log(y))
c(fit$details$order, fit$details$seasonal_order)
#> [1] 0 1 1 0 1 1
fit$aicc
#> [1] -483.204
exp(predict(fit, 6))
#>           Jan      Feb      Mar      Apr      May      Jun
#> 1961 450.4223 425.7170 479.0062 492.4044 509.0549 583.3447
```

## Prophet-style trend

[`model_prophet()`](https://strategicprojects.github.io/foresightr/reference/model_prophet.md)
fits a trend that may bend at many places, shrinking the bends that do
not matter to exactly zero, plus Fourier seasonality:

``` r

fit <- fit_model(model_prophet(), log(y))
fit$details$changepoints
#>  [1]  10  15  19  28  37  51  60  65  88 101 115
```

Events and lasting steps are covered in
[`vignette("regressors")`](https://strategicprojects.github.io/foresightr/articles/regressors.md).

## TBATS

[`model_tbats()`](https://strategicprojects.github.io/foresightr/reference/model_tbats.md)
handles several seasonal periods, including periods that are not whole
numbers (52.18 weeks in a year), with trigonometric terms. Whatever is
not fixed is chosen by AIC, which takes seconds.

``` r

fit <- fit_model(model_tbats(), y)
fit$details[c("harmonics", "lambda", "trend", "arma")]
#> $harmonics
#> [1] 5
#> 
#> $lambda
#> [1] 2.306312e-05
#> 
#> $trend
#> [1] TRUE
#> 
#> $arma
#> [1] 0 0
```

## Intermittent demand

For series where most periods have no demand, the forecast is a rate:
Croston’s method and its SBA and TSB variants.

``` r

demand <- c(0, 0, 3, 0, 0, 0, 2, 0, 0, 4, 0, 0, 0, 0, 3, 0, 2, 0, 0, 0)
forecast_model(model_croston("sba"), demand, 3)
#> [1] 0.8762393 0.8762393 0.8762393
```

## Combining models

Any model can run on the log or Box-Cox scale, and on the seasonally
adjusted series:

``` r

model_name(model_log(model_decomposed(model_auto_ets())))
#> [1] "log_stl_auto_ets"
forecast_model(model_box_cox(model_theta(), "guerrero"), y, 3)
#>           Jan      Feb      Mar
#> 1961 446.6416 437.0833 521.2054
```

An ensemble learns its weights from its members’ errors on the end of
the series; with `"stacked"` weights, members that add nothing get
exactly zero.

``` r

fit <- fit_model(model_ensemble(candidates_default(), weighting = "stacked"), y)
round(fit$params[fit$params > 0], 3)
#>                 weight_naive        weight_seasonal_naive 
#>                        0.010                        0.059 
#> weight_seasonal_naive_growth          weight_holt_winters 
#>                        0.046                        0.503 
#>            weight_log_linear 
#>                        0.382
```

## The ready sets

``` r

vapply(candidates_default(), model_name, "")
#>  [1] "naive"                 "drift"                 "seasonal_naive"       
#>  [4] "seasonal_naive_growth" "theta"                 "holt_winters"         
#>  [7] "log_linear"            "arima_011_011"         "log_arima_011_011"    
#> [10] "prophet"               "log_prophet"
length(candidates_thorough())
#> [1] 18
```

[`candidates_thorough()`](https://strategicprojects.github.io/foresightr/reference/candidates_default.md)
adds the automatic choices and two ensembles, and takes seconds rather
than milliseconds in a backtest.
