# Argument checks and series handling shared by the package.

`%||%` <- function(x, y) if (is.null(x)) y else x

abort <- function(...) stop(paste0(...), call. = FALSE)

check_count <- function(x, what, min = 0, null = FALSE) {
  if (null && is.null(x)) return(NULL)
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || x != round(x) || x < min) {
    abort("`", what, "` must be a whole number of at least ", min, ".")
  }
  as.numeric(x)
}

check_counts <- function(x, what, n = NULL, null = FALSE) {
  if (null && is.null(x)) return(NULL)
  if (!is.numeric(x) || anyNA(x) || any(x != round(x)) || any(x < 0) ||
      (!is.null(n) && length(x) != n)) {
    abort("`", what, "` must be ",
          if (is.null(n)) "whole numbers" else paste(n, "whole numbers"), ", none negative.")
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
    period <- check_count(period %||% 1, "period", min = 1)
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

# Times of the periods after the end of the series (NULL without a `ts`).
times_after <- function(h, series) {
  if (is.null(series$tsp)) return(NULL)
  series$tsp[2] + seq_len(h) / series$tsp[3]
}

# A matrix from a vector filled row by row: [row][column].
by_row <- function(x, rows) {
  if (rows == 0) return(matrix(numeric(0), 0, 0))
  matrix(x, nrow = rows, byrow = TRUE)
}

level_names <- function(levels) paste0(round(levels * 100))
