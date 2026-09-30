#' Threads used by backtests and ensembles
#'
#' Backtests and ensembles fit on several threads: by default, all the cores
#' of the machine. `foresight_threads(n)` limits them to `n`, for the whole
#' session; `foresight_threads(0)` removes the limit. The results do not
#' depend on the number of threads.
#'
#' When the package is loaded the limit comes from the option
#' `foresightr.threads` or, failing that, from the environment variable
#' `OMP_THREAD_LIMIT`; under `R CMD check` it is 2.
#'
#' @param n The most threads to use, or 0 for all cores. `NULL` changes
#'   nothing.
#' @return The number of threads in use after the call; invisibly when it was
#'   set.
#' @examples
#' foresight_threads()
#' @export
foresight_threads <- function(n = NULL) {
  if (is.null(n)) return(rs_threads(NaN))
  invisible(rs_threads(check_count(n, "n", max = 4096)))
}

.onLoad <- function(libname, pkgname) {
  limit <- getOption("foresightr.threads")
  if (is.null(limit)) {
    omp <- suppressWarnings(as.integer(Sys.getenv("OMP_THREAD_LIMIT", "")))
    checking <- nzchar(Sys.getenv("_R_CHECK_LIMIT_CORES_", "")) &&
      !identical(tolower(Sys.getenv("_R_CHECK_LIMIT_CORES_")), "false")
    limit <- if (checking) 2L else if (!is.na(omp) && omp > 0) omp else NULL
  }
  if (is.numeric(limit) && length(limit) == 1 && !is.na(limit) && limit >= 0) {
    rs_threads(min(as.numeric(limit), 4096))
  }
}
