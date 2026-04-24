\name{run_app}
\alias{run_app}
\title{Launch the Agent Dagwood Shiny app}
\usage{
run_app(launch.browser = interactive(), ...)
}
\arguments{
\item{launch.browser}{Logical. Whether to open a browser automatically.}

\item{...}{Additional arguments passed to \code{shiny::runApp()}.}
}
\value{
Invisibly returns the running Shiny app object.
}
\description{
Starts the packaged Shiny app for scenario-to-DAG analysis and assumption evaluation.
}
