## Submission

This is a new submission.

## Test environments

* local: macOS 15 (aarch64), R 4.6.0, rustc 1.97.0
* GitHub Actions: macOS (release), Windows (release), Ubuntu (devel, release,
  oldrel-1), rustc 1.98.1
* rustc 1.81.0 (the oldest version the package declares): builds and passes
  its tests

## R CMD check results

0 errors | 0 warnings | 1 note

* New submission. The words flagged as possibly misspelled in DESCRIPTION are
  names of authors and of methods (ARIMA, TBATS, LOESS, Croston, Hyndman...).

## Rust

The package contains Rust code (through 'extendr').

* The sources of all the Rust crates it depends on are bundled in
  `src/rust/vendor.tar.xz`, and the build runs `cargo build --offline`:
  nothing is downloaded.
* `cargo build` runs with `-j 2`, and CARGO_HOME is a temporary directory
  inside the build tree, removed at the end.
* The versions of cargo and rustc are reported before compilation
  (`tools/msrv.R`), and `SystemRequirements` states the minimum rustc (1.81).
* The authors and licenses of the bundled crates are listed in `inst/AUTHORS`
  and credited in `Authors@R`.

## Threads

Backtests and ensembles run on several threads. Under `R CMD check`
(`_R_CHECK_LIMIT_CORES_`) and when `OMP_THREAD_LIMIT` is set, the package
limits itself to that number of threads (2 on CRAN); the tests set the limit
to 2 explicitly.
