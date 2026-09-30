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
