# Name and description of a model

Name and description of a model

## Usage

``` r
model_name(model)

model_description(model)
```

## Arguments

- model:

  A model.

## Value

`model_name()`: the short name used in reports, such as
`"log_arima_011_011"`; `model_description()`: one line about the method.

## Examples

``` r
model_name(model_log(model_airline()))
#> [1] "log_arima_011_011"
```
