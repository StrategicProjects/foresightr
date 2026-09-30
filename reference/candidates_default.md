# Ready sets of candidates

`candidates_default()` has the benchmarks and every model that needs no
external data and fits in a moment: naive, drift, seasonal naive (plain
and with growth), Theta, Holt-Winters, log-linear regression, the
airline ARIMA and Prophet (each on the original and the log scale): 11
models. `candidates_thorough()` adds two ensembles of those (inverse
error and stacked), ETS chosen automatically (alone, after STL, and
after STL on the log scale) and ARIMA with automatic orders (original
and log): 18 models, seconds rather than milliseconds in a backtest.

## Usage

``` r
candidates_default()

candidates_thorough()
```

## Value

A list of models.

## Examples

``` r
vapply(candidates_default(), model_name, "")
#>  [1] "naive"                 "drift"                 "seasonal_naive"       
#>  [4] "seasonal_naive_growth" "theta"                 "holt_winters"         
#>  [7] "log_linear"            "arima_011_011"         "log_arima_011_011"    
#> [10] "prophet"               "log_prophet"          
```
