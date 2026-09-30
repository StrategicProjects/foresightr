# Package index

## Choose a model

Replay the past with several candidates and keep what would have worked.

- [`backtest()`](https://strategicprojects.github.io/foresightr/reference/backtest.md)
  : Choose a model by what would have worked
- [`total_forecast()`](https://strategicprojects.github.io/foresightr/reference/total_forecast.md)
  : Forecast of a total
- [`autoplot(`*`<foresight_backtest>`*`)`](https://strategicprojects.github.io/foresightr/reference/autoplot.foresight_backtest.md)
  [`plot(`*`<foresight_backtest>`*`)`](https://strategicprojects.github.io/foresightr/reference/autoplot.foresight_backtest.md)
  [`autoplot(`*`<foresight_decomposition>`*`)`](https://strategicprojects.github.io/foresightr/reference/autoplot.foresight_backtest.md)
  [`plot(`*`<foresight_decomposition>`*`)`](https://strategicprojects.github.io/foresightr/reference/autoplot.foresight_backtest.md)
  : Charts of a backtest or a decomposition
- [`theme_foresight()`](https://strategicprojects.github.io/foresightr/reference/theme_foresight.md)
  : The theme of the package's charts
- [`candidates_default()`](https://strategicprojects.github.io/foresightr/reference/candidates_default.md)
  [`candidates_thorough()`](https://strategicprojects.github.io/foresightr/reference/candidates_default.md)
  : Ready sets of candidates

## Fit and forecast

- [`fit_model()`](https://strategicprojects.github.io/foresightr/reference/fit_model.md)
  [`predict(`*`<foresight_fit>`*`)`](https://strategicprojects.github.io/foresightr/reference/fit_model.md)
  [`forecast_model()`](https://strategicprojects.github.io/foresightr/reference/fit_model.md)
  : Fit a model and forecast

## Models

- [`model_arima()`](https://strategicprojects.github.io/foresightr/reference/model_arima.md)
  [`model_airline()`](https://strategicprojects.github.io/foresightr/reference/model_arima.md)
  : Seasonal ARIMA
- [`model_auto_arima()`](https://strategicprojects.github.io/foresightr/reference/model_auto_arima.md)
  : ARIMA with automatic orders
- [`model_box_cox()`](https://strategicprojects.github.io/foresightr/reference/model_box_cox.md)
  [`model_log()`](https://strategicprojects.github.io/foresightr/reference/model_box_cox.md)
  : A model on the log or Box-Cox scale
- [`model_croston()`](https://strategicprojects.github.io/foresightr/reference/model_croston.md)
  : Intermittent demand
- [`model_decomposed()`](https://strategicprojects.github.io/foresightr/reference/model_decomposed.md)
  : Forecast the seasonally adjusted series
- [`model_ensemble()`](https://strategicprojects.github.io/foresightr/reference/model_ensemble.md)
  : Several models combined
- [`model_ets()`](https://strategicprojects.github.io/foresightr/reference/model_ets.md)
  [`model_auto_ets()`](https://strategicprojects.github.io/foresightr/reference/model_ets.md)
  : Exponential smoothing
- [`model_holt_winters()`](https://strategicprojects.github.io/foresightr/reference/model_holt_winters.md)
  : Holt-Winters
- [`model_log_linear()`](https://strategicprojects.github.io/foresightr/reference/model_log_linear.md)
  : Log-linear regression
- [`model_mean()`](https://strategicprojects.github.io/foresightr/reference/model_mean.md)
  [`model_naive()`](https://strategicprojects.github.io/foresightr/reference/model_mean.md)
  [`model_drift()`](https://strategicprojects.github.io/foresightr/reference/model_mean.md)
  [`model_seasonal_naive()`](https://strategicprojects.github.io/foresightr/reference/model_mean.md)
  : Benchmark models
- [`model_prophet()`](https://strategicprojects.github.io/foresightr/reference/model_prophet.md)
  : Prophet-style trend with changepoints and events
- [`model_tbats()`](https://strategicprojects.github.io/foresightr/reference/model_tbats.md)
  : TBATS
- [`model_theta()`](https://strategicprojects.github.io/foresightr/reference/model_theta.md)
  : Theta method

## Combine and transform models

- [`model_box_cox()`](https://strategicprojects.github.io/foresightr/reference/model_box_cox.md)
  [`model_log()`](https://strategicprojects.github.io/foresightr/reference/model_box_cox.md)
  : A model on the log or Box-Cox scale
- [`model_decomposed()`](https://strategicprojects.github.io/foresightr/reference/model_decomposed.md)
  : Forecast the seasonally adjusted series
- [`model_ensemble()`](https://strategicprojects.github.io/foresightr/reference/model_ensemble.md)
  : Several models combined
- [`with_name()`](https://strategicprojects.github.io/foresightr/reference/with_name.md)
  : Rename a model
- [`model_name()`](https://strategicprojects.github.io/foresightr/reference/model_name.md)
  [`model_description()`](https://strategicprojects.github.io/foresightr/reference/model_name.md)
  : Name and description of a model

## Decompose and clean

- [`decompose_stl()`](https://strategicprojects.github.io/foresightr/reference/decompose_stl.md)
  [`decompose_mstl()`](https://strategicprojects.github.io/foresightr/reference/decompose_stl.md)
  : Decompose a series by STL or MSTL
- [`fill_gaps()`](https://strategicprojects.github.io/foresightr/reference/fill_gaps.md)
  [`find_outliers()`](https://strategicprojects.github.io/foresightr/reference/fill_gaps.md)
  [`clean_series()`](https://strategicprojects.github.io/foresightr/reference/fill_gaps.md)
  : Gaps and outliers

## Tests, measures and regressors

- [`kpss_statistic()`](https://strategicprojects.github.io/foresightr/reference/kpss_statistic.md)
  [`n_differences()`](https://strategicprojects.github.io/foresightr/reference/kpss_statistic.md)
  [`n_seasonal_differences()`](https://strategicprojects.github.io/foresightr/reference/kpss_statistic.md)
  [`seasonal_strength()`](https://strategicprojects.github.io/foresightr/reference/kpss_statistic.md)
  [`autocorrelations()`](https://strategicprojects.github.io/foresightr/reference/kpss_statistic.md)
  [`box_cox()`](https://strategicprojects.github.io/foresightr/reference/kpss_statistic.md)
  [`inv_box_cox()`](https://strategicprojects.github.io/foresightr/reference/kpss_statistic.md)
  [`guerrero_lambda()`](https://strategicprojects.github.io/foresightr/reference/kpss_statistic.md)
  : Tests and transformations
- [`mape()`](https://strategicprojects.github.io/foresightr/reference/mape.md)
  [`pct_bias()`](https://strategicprojects.github.io/foresightr/reference/mape.md)
  [`mae()`](https://strategicprojects.github.io/foresightr/reference/mape.md)
  [`rmse()`](https://strategicprojects.github.io/foresightr/reference/mape.md)
  [`mase()`](https://strategicprojects.github.io/foresightr/reference/mape.md)
  : Accuracy of forecasts
- [`fourier_terms()`](https://strategicprojects.github.io/foresightr/reference/fourier_terms.md)
  [`seasonal_dummies()`](https://strategicprojects.github.io/foresightr/reference/fourier_terms.md)
  : External variables for a regression with ARIMA errors

## Package

- [`foresightr`](https://strategicprojects.github.io/foresightr/reference/foresightr-package.md)
  [`foresightr-package`](https://strategicprojects.github.io/foresightr/reference/foresightr-package.md)
  : foresightr: Forecasts Chosen by What Would Have Worked
