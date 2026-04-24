`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

read_scenario <- function(filename) {
  path <- system.file("extdata", "scenario", filename, package = "agentdagwood")
  paste(readLines(path, warn = FALSE), collapse = "\n")
}
