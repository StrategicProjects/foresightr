# foresightr 0.1.0

First release: R interface to the Rust crate foresight 0.7.2.

* Models as specifications (`model_*()`): benchmarks, Theta, Holt-Winters,
  log-linear regression, seasonal ARIMA with regressors and automatic orders,
  exponential smoothing with automatic choice, a Prophet-style trend with
  events, TBATS, Croston with its variants, forecasts of the seasonally
  adjusted series, ensembles and Box-Cox scales.
* `backtest()`: rolling origin on several threads (`foresight_threads()`),
  errors by horizon, the choice by out-of-sample error and empirical intervals
  by horizon and for totals (`total_forecast()`).
* `decompose_stl()`, `decompose_mstl()`, `fill_gaps()`, `find_outliers()`,
  `clean_series()`, tests of stationarity and seasonality, accuracy measures.
* Charts with ggplot2: `autoplot()` and `theme_foresight()`.
