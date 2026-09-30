# Threads used by backtests and ensembles

Backtests and ensembles fit on several threads: by default, all the
cores of the machine. `foresight_threads(n)` limits them to `n`, for the
whole session; `foresight_threads(0)` removes the limit. The results do
not depend on the number of threads.

## Usage

``` r
foresight_threads(n = NULL)
```

## Arguments

- n:

  The most threads to use, or 0 for all cores. `NULL` changes nothing.

## Value

The number of threads in use after the call; invisibly when it was set.

## Details

When the package is loaded the limit comes from the option
`foresightr.threads` or, failing that, from the environment variable
`OMP_THREAD_LIMIT`; under `R CMD check` it is 2.

## Examples

``` r
foresight_threads()
#> [1] 4
```
