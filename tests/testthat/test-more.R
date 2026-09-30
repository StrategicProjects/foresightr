skip_if_not_installed("jsonlite")
more <- recorded("rust_more")

test_that("STL as in Rust", {
  y <- log(AirPassengers)
  cases <- list(
    periodic = list(),
    span13 = list(seasonal_window = 13),
    robust7 = list(seasonal_window = 7, robust = TRUE),
    robust5rounds = list(seasonal_window = 7, robust = TRUE, inner = 1, outer = 5),
    degree1 = list(seasonal_window = 11, degrees = c(1, 1, 1), trend_window = 21),
    flat = list(seasonal_window = 9, degrees = c(0, 0, 0))
  )
  for (name in names(cases)) {
    d <- do.call(decompose_stl, c(list(y), cases[[name]]))
    w <- more$stl[[name]]
    near(d$seasonal[, 1], w$seasonal, computed)
    near(d$trend, w$trend, computed)
    near(d$trend_strength, w$trend_strength, computed)
    near(d$seasonal_strength, w$seasonal_strength, computed)
    expect_equal(as.numeric(d$trend + d$seasonal[, 1] + d$remainder), as.numeric(y),
                 tolerance = 1e-12)
  }
})

test_that("STL agrees with stats::stl", {
  y <- log(AirPassengers)
  ours <- decompose_stl(y, seasonal_window = 13)
  theirs <- stats::stl(y, s.window = 13)$time.series
  expect_equal(as.numeric(ours$seasonal[, 1]), as.numeric(theirs[, "seasonal"]), tolerance = 1e-8)
  expect_equal(as.numeric(ours$trend), as.numeric(theirs[, "trend"]), tolerance = 1e-8)
})

two_patterns <- function() {
  t <- 0:419
  weekly <- c(5, 0, -2, -3, 0, 1, -1)
  100 + 0.05 * t + weekly[t %% 7 + 1] + 8 * sin(2 * pi * t / 30) + 2 * sin(t * 1.7) * cos(t * 0.3)
}

test_that("MSTL and forecasts by decomposition as in Rust", {
  d <- decompose_mstl(two_patterns(), periods = c(30, 7))
  expect_equal(d$periods, c(7, 30))
  near(d$seasonal[, 1], more$mstl$seasonal7, 1e-8)
  near(d$seasonal[, 2], more$mstl$seasonal30, 1e-8)
  near(d$trend, more$mstl$trend, 1e-8)

  icms <- ts(piaui()$icms, frequency = 12)
  near(forecast_model(model_decomposed(model_naive()), icms, 12), more$decomposed$icms_naive, computed)
  near(forecast_model(model_decomposed(model_drift()), icms, 12), more$decomposed$icms_drift, computed)
  two <- forecast_model(model_decomposed(model_drift(), periods = c(7, 30)), two_patterns(), 40,
                        period = 7)
  near(two, more$decomposed$two, 1e-8)
  expect_equal(model_name(model_decomposed(model_drift())), "stl_drift")
})

test_that("Croston as in Rust", {
  t <- 0:59
  demand <- ifelse((t * 7) %% 10 < 3, 1 + (t * 3) %% 5, 0)
  w <- more$croston
  near(forecast_model(model_croston(), demand, 1), w$croston, computed)
  near(forecast_model(model_croston(alpha = 0.3), demand, 1), w$croston3, computed)
  near(forecast_model(model_croston("sba", alpha = 0.2), demand, 1), w$sba, computed)
  near(forecast_model(model_croston("tsb", alpha = 0.2, beta = 0.1), demand, 1), w$tsb, computed)
  near(forecast_model(model_croston(optimised = TRUE), demand, 1), w$optimised, searched)
  expect_error(fit_model(model_croston(), c(1, 0, -2, 0, 3)))
})

test_that("cleaning as in Rust", {
  dirty <- log(AirPassengers)
  dirty[30] <- dirty[30] + 0.8
  dirty[100] <- dirty[100] - 0.7
  dirty[61:62] <- NA
  icms <- piaui()$icms
  icms[40] <- icms[40] * 2
  icms[90] <- icms[90] * 0.4
  fpe <- piaui()$fpe
  cases <- list(air = list(dirty, NULL), icms = list(icms, 12), fpe = list(fpe, 12),
                air_flat = list(as.numeric(dirty), 1))
  for (name in names(cases)) {
    w <- more$clean[[name]]
    y <- cases[[name]][[1]]
    period <- cases[[name]][[2]]
    found <- find_outliers(y, period)
    expect_equal(found$index, as.numeric(unlist(w$index)) + 1)
    near(found$replacement, w$replacement, computed)
    near(clean_series(y, period), w$clean, computed)
    near(fill_gaps(y, period), w$filled, computed)
  }
})

for (name in c("icms", "fpe")) {
  test_that(paste("ensembles as in Rust:", name), {
    y <- series_of(name)
    cases <- list(inverse_error = list(), equal = list(weighting = "equal"),
                  median = list(weighting = "median"), stacked = list(weighting = "stacked"),
                  top3 = list(top = 3))
    for (key in names(cases)) {
      w <- more$ensemble[[name]][[key]]
      fit <- fit_model(do.call(model_ensemble, c(list(candidates_default()), cases[[key]])), y)
      expect_equal(names(fit$params), unlist(w$names))
      near(fit$params, w$weights, 1e-4)
      near(predict(fit, 12), w$forecast, searched)
    }
  })

  test_that(paste("TBATS as in Rust:", name), {
    skip_on_cran()
    y <- series_of(name)
    cases <- list(
      plain = model_tbats(harmonics = 3, box_cox = FALSE, trend = TRUE, damped = FALSE,
                          arma_errors = FALSE),
      boxcox = model_tbats(harmonics = 3, box_cox = TRUE, trend = TRUE, damped = TRUE,
                           arma_errors = FALSE),
      arma = model_tbats(harmonics = 2, box_cox = FALSE, trend = FALSE, arma_orders = c(1, 1)),
      auto = model_tbats()
    )
    for (key in names(cases)) {
      w <- more$tbats[[name]][[key]]
      fit <- fit_model(cases[[key]], y)
      d <- fit$details
      expect_equal(d$harmonics, w$harmonics)
      expect_equal(d$trend, w$trend)
      expect_equal(!is.na(d$damping) && d$damping < 1, w$damped)
      expect_equal(!is.na(d$lambda), w$box_cox)
      expect_equal(d$arma, as.numeric(unlist(w$arma)))
      near(d$minus_two_log_likelihood, w$likelihood, 1e-6)
      expect_true(is.na(fit$log_likelihood))
      near(fit$aic, w$aic, 1e-6)
      near(predict(fit, 12), w$forecast, 5e-3)
    }
  })

  test_that(paste("thorough backtest as in Rust:", name), {
    skip_on_cran()
    w <- more$thorough[[name]]
    bt <- backtest(series_of(name), candidates_thorough())
    expect_equal(bt$best, w$chosen)
    expect_equal(bt$ranking$name, vapply(w$scores, function(s) s[[1]], ""))
    near(bt$ranking$score, vapply(w$scores, function(s) s[[2]], 0), 1e-3)
    near(bt$forecast$mean, w$forecast, 1e-4)
  })
}
