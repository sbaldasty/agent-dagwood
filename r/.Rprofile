if (file.exists("renv/activate.R")) {
  source("renv/activate.R")
}

if (interactive()) {
  options(device = function(...) {
    httpgd::hgd(...)
  })
}