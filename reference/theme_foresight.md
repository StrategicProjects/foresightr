# The theme of the package's charts

A quiet theme on top of
[`ggplot2::theme_minimal()`](https://ggplot2.tidyverse.org/reference/ggtheme.html):
horizontal grid lines only, muted axes, the title aligned with the plot.

## Usage

``` r
theme_foresight(base_size = 11, base_family = "")
```

## Arguments

- base_size:

  Base font size.

- base_family:

  Base font family.

## Value

A ggplot2 theme.

## Examples

``` r
library(ggplot2)
ggplot(data.frame(x = 1:10, y = cumsum(rnorm(10))), aes(x, y)) +
  geom_line() +
  theme_foresight()
```
