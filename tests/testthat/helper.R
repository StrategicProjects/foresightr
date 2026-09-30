# Results recorded by the Rust crate on x86-64 Linux; the package runs the
# crate itself, so only the floating point of each platform differs. The
# tolerances are those of the Go edition, which reproduces the same numbers
# independently.
recorded <- function(name) {
  jsonlite::fromJSON(test_path("data", paste0(name, ".json")), simplifyVector = FALSE)
}

near <- function(ours, theirs, tolerance) {
  theirs <- as.numeric(unlist(theirs))
  ours <- as.numeric(ours)
  expect_equal(length(ours), length(theirs))
  expect_true(all(abs(ours - theirs) <= tolerance * pmax(abs(theirs), 1)),
              label = paste("largest relative difference",
                            signif(max(abs(ours - theirs) / pmax(abs(theirs), 1)), 3)))
}

searched <- 1e-5
computed <- 1e-9

piaui <- function() {
  read.csv(system.file("extdata", "piaui_revenue.csv", package = "foresightr"), comment.char = "#")
}

series_of <- function(name) {
  if (name == "air") return(AirPassengers)
  data <- piaui()
  ts(data[[name]], start = c(2017, 3), frequency = 12)
}
