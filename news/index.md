# Changelog

## foresightr 0.1.0

First release: R interface to the Rust crate foresight 0.7.3.

- Models as specifications (`model_*()`): benchmarks, Theta,
  Holt-Winters, log-linear regression, seasonal ARIMA with regressors
  and automatic orders, exponential smoothing with automatic choice, a
  Prophet-style trend with events, TBATS, Croston with its variants,
  forecasts of the seasonally adjusted series, ensembles and Box-Cox
  scales.
- [`backtest()`](https://strategicprojects.github.io/foresightr/reference/backtest.md):
  rolling origin on several threads
  ([`foresight_threads()`](https://strategicprojects.github.io/foresightr/reference/foresight_threads.md)),
  errors by horizon, the choice by out-of-sample error and empirical
  intervals by horizon and for totals
  ([`total_forecast()`](https://strategicprojects.github.io/foresightr/reference/total_forecast.md)).
- [`decompose_stl()`](https://strategicprojects.github.io/foresightr/reference/decompose_stl.md),
  [`decompose_mstl()`](https://strategicprojects.github.io/foresightr/reference/decompose_stl.md),
  [`fill_gaps()`](https://strategicprojects.github.io/foresightr/reference/fill_gaps.md),
  [`find_outliers()`](https://strategicprojects.github.io/foresightr/reference/fill_gaps.md),
  [`clean_series()`](https://strategicprojects.github.io/foresightr/reference/fill_gaps.md),
  tests of stationarity and seasonality, accuracy measures.
- Charts with ggplot2:
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  and
  [`theme_foresight()`](https://strategicprojects.github.io/foresightr/reference/theme_foresight.md).
