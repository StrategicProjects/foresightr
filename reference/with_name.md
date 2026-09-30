# Rename a model

Sets the name (and description) under which a model appears in a
backtest or an ensemble.

## Usage

``` r
with_name(model, name, description = NULL)
```

## Arguments

- model:

  A model.

- name:

  The new name.

- description:

  The new description; by default the model's own.

## Value

The model, renamed.

## Examples

``` r
model <- with_name(model_seasonal_naive(), "same_month", "The same month of last year")
model
#> <foresight model> same_month
#> The same month of last year
```
