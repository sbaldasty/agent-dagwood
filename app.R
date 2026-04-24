if (!requireNamespace("agentdagwood", quietly = TRUE)) {
  stop(
    "The 'agentdagwood' package is required. Install with install.packages('agentdagwood') or devtools::install_local('.').",
    call. = FALSE
  )
}

agentdagwood::run_app()
