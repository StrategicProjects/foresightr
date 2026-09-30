test_that("a ts brings its period and season", {
  y <- window(AirPassengers, start = c(1949, 3))
  plain <- as.numeric(y)
  expect_equal(forecast_model(model_theta(), plain, 3, period = 12),
               as.numeric(forecast_model(model_theta(), y, 3)))
  f <- forecast_model(model_seasonal_naive(), y, 3)
  expect_true(is.ts(f))
  expect_equal(start(f), c(1961, 1))
  expect_error(fit_model(model_theta(), y, period = 4), "contradicts")
})

test_that("arguments are checked", {
  expect_error(model_arima(c(1, 1)), "order")
  expect_error(model_ets(1), "code")
  expect_error(model_croston("xyz"))
  expect_error(model_ensemble(model_theta()), "list of models")
  expect_error(fit_model(list(kind = "theta"), AirPassengers), "must be a model")
  expect_error(fit_model(model_holt_winters(), c(1, 2, 3), period = 12), "unsuitable")
  expect_error(fit_model(model_theta(), c(1, NA, 3)), "missing")
  expect_error(backtest(AirPassengers, metric = "r2"))
  expect_error(backtest(rep(1, 10), period = 12), "too short")
  expect_error(model_ets("XYZ") |> fit_model(AirPassengers), "ETS code")
})

test_that("names follow the crate", {
  expect_equal(model_name(model_log(model_airline())), "log_arima_011_011")
  expect_equal(model_name(model_box_cox(model_theta(), "guerrero")), "boxcox_theta")
  renamed <- with_name(model_theta(), "my_theta", "Theta, renamed")
  expect_equal(c(model_name(renamed), model_description(renamed)), c("my_theta", "Theta, renamed"))
  expect_length(candidates_default(), 11)
  expect_length(candidates_thorough(), 18)
})

test_that("the backtest report is complete", {
  bt <- backtest(AirPassengers, list(model_theta(), with_name(model_holt_winters(), "hw")),
                 origins = 12, horizon = 6)
  expect_equal(bt$ranking$name, c("theta", "hw", "mean(hw+theta)"))
  expect_equal(sum(bt$ranking$chosen), 1)
  expect_named(bt$forecast, c("horizon", "time", "mean", "lower_80", "upper_80", "lower_95",
                              "upper_95"))
  expect_true(all(bt$forecast$lower_80 <= bt$forecast$mean & bt$forecast$mean <= bt$forecast$upper_80))
  report <- bt$candidates[[bt$best]]
  expect_equal(dim(report$trajectories), c(12, 6))
  expect_equal(total_forecast(bt, 6)$mean, sum(bt$forecast$mean))
  expect_error(total_forecast(bt, 7), "beyond")
  expect_s3_class(as.data.frame(bt), "data.frame")
  expect_false(inherits(as.data.frame(bt), "tbl_df"))
  for (table in list(bt$ranking, bt$forecast, report$accuracy, report$bands, report$cumulative,
                     total_forecast(bt, 3), find_outliers(AirPassengers), fourier_terms(12, 2, 20),
                     seasonal_dummies(12, 20))) {
    expect_s3_class(table, "tbl_df")
  }
  expect_output(print(bt), "Chosen")
})

test_that("fits keep what was estimated", {
  fit <- fit_model(model_auto_ets(), AirPassengers)
  expect_output(print(fit), "auto_ets")
  expect_true(is.numeric(fit$aicc))
  expect_length(predict(fit, 5), 5)
  path <- tempfile(fileext = ".rds")
  saveRDS(fit, path)
  expect_error(predict(readRDS(path), 3), "fit the model again")
})

test_that("accuracy measures", {
  expect_equal(mape(c(100, 200), c(110, 180)), 10)
  expect_equal(pct_bias(c(100, 200), c(110, 220)), 10)
  expect_equal(mae(c(1, 2), c(2, 4)), 1.5)
  expect_equal(rmse(c(0, 0), c(3, 4)), sqrt(12.5))
  expect_equal(mase(c(3, 4), c(3, 4), 1:5), 0)
  expect_equal(inv_box_cox(box_cox(c(1, 2), 0.3), 0.3), c(1, 2))
  expect_error(mape(1:2, 1), "differ")
})

test_that("charts are ggplot objects", {
  bt <- backtest(AirPassengers, list(model_theta(), model_seasonal_naive()), origins = 12,
                 horizon = 6)
  for (type in c("forecast", "accuracy", "ranking")) {
    expect_s3_class(autoplot(bt, type), "ggplot")
  }
  expect_s3_class(autoplot(decompose_stl(log(AirPassengers))), "ggplot")
  expect_s3_class(theme_foresight(), "theme")
  expect_error(autoplot(bt, candidate = "nothing"), "no candidate")
})

# ---- what a review found (after 0.1.0)

test_that("a plain vector goes through the backtest and the charts", {
  v <- as.numeric(AirPassengers)
  bt <- backtest(v, list(model_theta(), model_seasonal_naive()), period = 12, origins = 12,
                 horizon = 6)
  expect_named(bt$forecast, c("horizon", "mean", "lower_80", "upper_80", "lower_95", "upper_95"))
  expect_equal(bt$forecast$mean,
               backtest(AirPassengers, list(model_theta(), model_seasonal_naive()), origins = 12,
                        horizon = 6)$forecast$mean)
  expect_s3_class(autoplot(bt), "ggplot")
  expect_equal(total_forecast(bt, 3)$mean, sum(bt$forecast$mean[1:3]))
})

test_that("candidates need distinct names", {
  expect_error(backtest(AirPassengers, list(model_theta(), model_theta())), "distinct names")
  bt <- backtest(AirPassengers, list(model_theta(), with_name(model_theta(), "again")),
                 origins = 12, horizon = 6, combine = 0)
  expect_equal(bt$ranking$name, c("theta", "again"))
})

test_that("the backtest says what is wrong", {
  expect_error(backtest(AirPassengers, levels = 80), "levels")
  expect_error(backtest(AirPassengers, levels = c(0.8, 0.8)), "differ")
  expect_error(backtest(AirPassengers, origins = 6), "too short")
  expect_error(backtest(AirPassengers, horizon = 0), "horizon")
  expect_error(backtest(AirPassengers - 300, list(model_holt_winters())), "no candidate")
  expect_warning(bt <- backtest(AirPassengers - 300, list(model_naive(), model_holt_winters())),
                 "holt_winters")
  expect_equal(bt$dropped, "holt_winters")
  negative <- backtest(-AirPassengers, list(model_naive()), combine = 0)
  expect_true(all(negative$forecast$lower_80 <= negative$forecast$upper_80))
  last_zero <- AirPassengers
  last_zero[144] <- 0
  expect_warning(bt <- backtest(last_zero), "left out")
  expect_true("naive" %in% bt$ranking$name)
})

test_that("a horizon without usable errors has no interval", {
  y <- AirPassengers[1:120]
  y[108] <- 0
  bt <- backtest(ts(y, frequency = 12), list(model_seasonal_naive()), origins = 12,
                 horizon = 12, combine = 0)
  expect_true(is.na(bt$forecast$lower_80[12]))
  expect_false(anyNA(bt$forecast$lower_80[1:11]))
  zeros <- backtest(ts(c(rep(5, 60), rep(0, 60)), frequency = 12), list(model_naive()),
                    origins = 12, horizon = 6, combine = 0)
  expect_true(all(is.na(zeros$forecast$lower_80)))
  expect_s3_class(autoplot(zeros), "ggplot")
  none <- backtest(AirPassengers, list(model_theta()), levels = numeric(0))
  expect_named(none$forecast, c("horizon", "time", "mean"))
  expect_s3_class(autoplot(none), "ggplot")
  wide <- backtest(AirPassengers, list(model_theta()), levels = c(0.8, 0.995))
  expect_true(all(c("lower_99.5", "upper_99.5") %in% names(wide$forecast)))
})

test_that("sizes are kept within reason", {
  expect_error(forecast_model(model_theta(), AirPassengers, 2^53), "whole number")
  expect_error(forecast_model(model_theta(), AirPassengers, Inf), "whole number")
  expect_error(model_auto_arima(d = Inf), "whole number")
  expect_error(model_arima(c(Inf, 0, 0)), "order")
  expect_error(autocorrelations(1:20, 1e13), "whole number")
  expect_error(fourier_terms(12, 1, 1e13), "whole number")
  expect_error(fourier_terms(0, 1, 10), "above 1")
  expect_error(decompose_stl(log(AirPassengers), inner = Inf), "whole number")
  expect_error(decompose_stl(log(AirPassengers), degrees = c(2, 2, 2)), "degrees")
  expect_error(decompose_stl(log(AirPassengers), degrees = 1), "degrees")
  expect_error(model_prophet(events = list(a = 0)), "from 1")
  expect_error(with_name(model_theta(), NA_character_), "string")
  expect_error(autoplot(backtest(AirPassengers, list(model_theta())), history = 0), "history")
})

test_that("integer input is read", {
  fit <- fit_model(model_tbats(periods = 12L, harmonics = 2, box_cox = FALSE,
                               arma_errors = FALSE),
                   as.numeric(AirPassengers))
  expect_equal(fit$details$periods, 12)
  expect_equal(forecast_model(model_theta(), 1:60, 3), forecast_model(model_theta(), as.numeric(1:60), 3))
})

test_that("regressors have to reach the horizon", {
  model <- model_arima(c(1, 0, 0), regressors = data.frame(x = sin(seq_len(150))))
  fit <- fit_model(model, AirPassengers)
  expect_length(predict(fit, 6), 6)
  expect_error(predict(fit, 12), "regressors")
  expect_error(forecast_model(model_log(model), AirPassengers, 12), "unsuitable")
})

test_that("exact series are handled", {
  expect_equal(as.numeric(forecast_model(model_auto_arima(), rep(5, 60), 2, period = 12)), c(5, 5))
  expect_equal(nrow(find_outliers(rep(3, 40))), 0)
  short <- forecast_model(model_prophet(), ts(c(52, 57, 51, 59, 55, 53, 58, 54), frequency = 12), 6)
  expect_true(all(short > 30 & short < 90))
})

test_that("threads can be limited without changing the results", {
  before <- foresight_threads()
  foresight_threads(1)
  one <- backtest(AirPassengers, origins = 12)
  foresight_threads(2)
  two <- backtest(AirPassengers, origins = 12)
  foresight_threads(before)
  expect_equal(one$ranking$score, two$ranking$score)
  expect_equal(foresight_threads(), before)
})
