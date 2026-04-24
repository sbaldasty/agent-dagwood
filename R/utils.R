`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

read_extdata_text <- function(filename) {
  file_path <- system.file("extdata", filename, package = "agentdagwood")
  if (!nzchar(file_path)) {
    stop(sprintf("Missing bundled example file: %s", filename), call. = FALSE)
  }

  paste(readLines(file_path, warn = FALSE), collapse = "\n")
}
