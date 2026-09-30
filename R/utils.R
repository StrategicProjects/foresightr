# Argument checks and series handling shared by the package.

`%||%` <- function(x, y) if (is.null(x)) y else x

abort <- function(...) stop(paste0(...), call. = FALSE)

# Sizes that drive allocations or loops are kept within reason: a larger
# number is a mistake, and would exhaust memory or never return.
most <- 1e6

check_count <- function(x, what, min = 0, max = most, null = FALSE) {
  if (null && is.null(x)) return(NULL)
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || x != round(x) || x < min || x > max) {
    abort("`", what, "` must be a whole number from ", min, " to ", format(max, big.mark = ",", scientific = FALSE),
          ".")
  }
  as.numeric(x)
}

check_counts <- function(x, what, n = NULL, min = 0, max = most, null = FALSE) {
  if (null && is.null(x)) return(NULL)
  if (!is.numeric(x) || anyNA(x) || any(x != round(x)) || any(x < min) || any(x > max) ||
      (!is.null(n) && length(x) != n)) {
    abort("`", what, "` must be ",
          if (is.null(n)) "whole numbers" else paste(n, "whole numbers"), " from ", min, " to ",
          format(max, big.mark = ",", scientific = FALSE), ".")
  }
  as.numeric(x)
}

check_number <- function(x, what, null = FALSE) {
  if (null && is.null(x)) return(NULL)
  if (!is.numeric(x) || length(x) != 1 || !is.finite(x)) {
    abort("`", what, "` must be a finite number.")
  }
  as.numeric(x)
}

check_flag <- function(x, what, null = FALSE) {
  if (null && is.null(x)) return(NULL)
  if (!is.logical(x) || length(x) != 1 || is.na(x)) {
    abort("`", what, "` must be TRUE or FALSE.")
  }
  x
}

check_numbers <- function(x, what, missing = FALSE) {
  if (is.data.frame(x) && ncol(x) == 1) x <- x[[1]]
  if (!is.numeric(x) || !is.null(dim(x)) && NCOL(x) > 1) {
    abort("`", what, "` must be a numeric vector or a `ts`.")
  }
  if (!missing && anyNA(x)) {
    abort("`", what, "` has missing values: fill them first, e.g. with `fill_gaps()`.")
  }
  as.numeric(x)
}

# NaN from the Rust side stands for "not available".
na <- function(x) {
  x[is.nan(x)] <- NA_real_
  x
}

# The values, seasonal period and season of the first observation (0-based)
# of `y`, a numeric vector or a `ts`, plus what is needed to give results
# the time of the series.
as_series <- function(y, period = NULL, missing = FALSE) {
  values <- check_numbers(y, "y", missing = missing)
  if (stats::is.ts(y)) {
    frequency <- stats::frequency(y)
    if (frequency != round(frequency)) {
      abort("the frequency of `y` must be a whole number; use `model_tbats(periods = )` ",
            "for periods such as 52.18.")
    }
    if (!is.null(period) && period != frequency) {
      abort("`period` = ", period, " contradicts the frequency of `y` (", frequency, ").")
    }
    period <- frequency
    phase <- (stats::cycle(y)[1] - 1) %% period
    tsp <- stats::tsp(y)
  } else {
    period <- check_count(period %||% 1, "period", min = 1, max = 1e5)
    phase <- 0
    tsp <- NULL
  }
  list(values = values, period = as.numeric(period), phase = as.numeric(phase), tsp = tsp)
}

# Values after the end of the series, as a `ts` when the series was one.
after <- function(values, series) {
  if (is.null(series$tsp)) return(values)
  stats::ts(values, start = series$tsp[2] + 1 / series$tsp[3], frequency = series$tsp[3])
}

# Values over the span of the series, as a `ts` when the series was one.
along <- function(values, series) {
  if (is.null(series$tsp)) return(values)
  stats::ts(values, start = series$tsp[1], frequency = series$tsp[3])
}

# Times of a `ts` as dates for monthly and quarterly data, numbers otherwise.
as_time <- function(t, frequency) {
  if (!frequency %in% c(4, 12)) return(t)
  year <- floor(t + 1e-9)
  month <- round((t - year) * 12) + 1
  as.Date(sprintf("%04d-%02d-01", as.integer(year), as.integer(month)))
}

# Times of the periods after the end of the series (NULL without a `ts`).
times_after <- function(h, series) {
  if (is.null(series$tsp)) return(NULL)
  as_time(series$tsp[2] + seq_len(h) / series$tsp[3], series$tsp[3])
}

# A matrix from a vector filled row by row: [row][column].
by_row <- function(x, rows) {
  if (rows == 0) return(matrix(numeric(0), 0, 0))
  matrix(x, nrow = rows, byrow = TRUE)
}

# A level as a percentage for column names: 0.8 is "80", 0.995 is "99.5".
level_names <- function(levels) format(round(levels * 100, 4), trim = TRUE, drop0trailing = TRUE)
