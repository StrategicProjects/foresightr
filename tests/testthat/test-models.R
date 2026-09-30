skip_if_not_installed("jsonlite")
models <- recorded("rust_models")

for (name in c("air", "icms", "fpe")) {
  test_that(paste("ARIMA as in Rust:", name), {
    want <- models[[name]]
    y <- series_of(name)
    a <- fit_model(model_airline(), log(y))
    near(a$details$ma, want$airline$ma, 1e-3)
    near(a$details$seasonal_ma, want$airline$sma, 1e-3)
    near(a$log_likelihood, want$airline$loglik, 1e-7)
    near(a$aicc, want$airline$aicc, 1e-7)
    near(forecast_model(model_log(model_airline()), y, 12), want$airline$forecast, searched)

    m <- fit_model(model_arima(c(1, 1, 1), c(1, 0, 0), constant = TRUE), log(y))
    near(m$details$ar, want$mixed$ar, 1e-3)
    near(m$details$seasonal_ar, want$mixed$sar, 1e-3)
    near(m$details$constant, want$mixed$constant, 1e-4)
    near(m$log_likelihood, want$mixed$loglik, 1e-7)
    near(predict(m, 12), want$mixed$forecast, searched)

    auto <- fit_model(model_auto_arima(), log(y))
    expect_equal(c(auto$details$order, auto$details$seasonal_order),
                 as.numeric(unlist(want$auto_arima$order)))
    expect_equal(!is.na(auto$details$constant), want$auto_arima$constant)
    near(auto$aicc, want$auto_arima$aicc, 1e-6)
    near(predict(auto, 12), want$auto_arima$forecast, 1e-4)
  })

  test_that(paste("ETS as in Rust:", name), {
    want <- models[[name]]
    y <- series_of(name)
    for (code in names(want$ets)) {
      fit <- fit_model(model_ets(code), y)
      expect_equal(fit$details$code, code)
      near(fit$log_likelihood, want$ets[[code]]$loglik, 1e-6)
      near(fit$aicc, want$ets[[code]]$aicc, 1e-6)
      near(predict(fit, 12), want$ets[[code]]$forecast, 2e-3)
    }
    auto <- fit_model(model_auto_ets(), y)
    expect_equal(auto$details$code, want$auto_ets$code)
    near(auto$aicc, want$auto_ets$aicc, 1e-6)
  })

  test_that(paste("Prophet as in Rust:", name), {
    want <- models[[name]]
    y <- series_of(name)
    cases <- list(
      list(model_prophet(), y, want$prophet),
      list(model_prophet(fourier_order = 5), y, want$prophet5),
      list(model_prophet(), log(y), want$prophet_log)
    )
    for (case in cases) {
      fit <- fit_model(case[[1]], case[[2]])
      near(predict(fit, 12), case[[3]]$forecast, 1e-8)
      near(fit$details$sigma, case[[3]]$sigma, 1e-8)
      # positions from 1 in R
      expect_equal(fit$details$changepoints, as.numeric(unlist(case[[3]]$bends)) + 1)
    }
  })

  test_that(paste("diagnostics as in Rust:", name), {
    want <- models[[name]]
    y <- series_of(name)
    near(guerrero_lambda(y), want$guerrero, 1e-6)
    near(kpss_statistic(log(y)), want$kpss, 1e-8)
    expect_equal(n_differences(log(y)), want$ndiffs)
    expect_equal(n_seasonal_differences(log(y)), want$nsdiffs)
    near(seasonal_strength(log(y)), want$strength, 1e-8)
  })

  test_that(paste("default backtest as in Rust:", name), {
    want <- models[[name]]$backtest
    bt <- backtest(series_of(name))
    expect_equal(bt$best, want$chosen)
    expect_equal(bt$ranking$name, vapply(want$scores, function(s) s[[1]], ""))
    near(bt$ranking$score, vapply(want$scores, function(s) s[[2]], 0), 1e-4)
    near(bt$forecast$mean, want$forecast, searched)
  })
}

test_that("regression with ARIMA errors as in Rust", {
  want <- models$regression_index
  data <- piaui()
  model <- model_airline()
  model$regressors <- list(ipca = log(data$ipca_index))
  fit <- fit_model(model, ts(log(data$icms)[1:100], frequency = 12))
  near(fit$details$regression[["ipca"]], want$slope, 1e-4)
  near(fit$log_likelihood, want$loglik, 1e-7)
  near(predict(fit, 12), want$forecast, searched)

  want <- models$regression_fourier
  harmonic <- model_arima(c(1, 1, 1), constant = TRUE, regressors = fourier_terms(12, 3, 156))
  expect_equal(model_name(harmonic), "arima_111_x")
  fit <- fit_model(harmonic, log(AirPassengers))
  near(fit$details$constant, want$constant, 1e-4)
  near(fit$log_likelihood, want$loglik, 1e-7)
  near(predict(fit, 12), want$forecast, searched)
  expect_equal(names(fit$details$regression)[1], "sin1_12")
})

test_that("Prophet events and steps as in Rust", {
  want <- models$events
  pattern <- c(5, -3, 0, 2, -4, 1, 3, -2, 0, 4, -5, 4)
  i <- 0:119
  y <- 200 + 0.8 * i + pattern[i %% 12 + 1] + ((i * 37) %% 11) * 0.3
  y[i %in% c(10, 34, 58, 82, 106)] <- y[i %in% c(10, 34, 58, 82, 106)] + 20
  y[i >= 80] <- y[i >= 80] - 15
  model <- model_prophet(changepoints = 0,
                         events = list(campaign = c(11, 35, 59, 83, 107, 127)),
                         steps = list(new_law = 81))
  fit <- fit_model(model, ts(y, frequency = 12))
  near(fit$details$effects[c("campaign", "new_law")], want$effects, 1e-8)
  near(predict(fit, 12), want$forecast, 1e-8)
})
