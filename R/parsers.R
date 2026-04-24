parse_llm_graph <- function(response_text) {
  lines <- strsplit(response_text, "\n", fixed = TRUE)[[1]]
  lines <- trimws(gsub("\r", "", lines))
  lines <- lines[nzchar(lines)]
  lines <- lines[!grepl("^```", lines)]

  if (length(lines) < 3) {
    stop(
      "Model output could not be parsed. Expected treatment, outcome, and at least one edge.",
      call. = FALSE
    )
  }

  list(
    exposure = lines[1],
    outcome = lines[2],
    dag = paste(lines[-(1:2)], collapse = "\n")
  )
}

extract_assumptions <- function(dagwood_result) {
  summary_lines <- strsplit(dagwood_result$Summary, "\n", fixed = TRUE)[[1]]
  summary_lines <- trimws(summary_lines)
  assumptions <- summary_lines[startsWith(summary_lines, ".")]
  assumptions <- sub("^\\.\\s*", "", assumptions)
  assumptions[nzchar(assumptions)]
}

parse_assessment_response <- function(response_text) {
  trimmed <- trimws(response_text)

  if (startsWith(trimmed, "Agree.")) {
    explanation <- trimws(sub("^Agree\\.\\s*", "", trimmed))
    return(list(verdict = "Agree", explanation = explanation))
  }

  if (startsWith(trimmed, "Disagree.")) {
    explanation <- trimws(sub("^Disagree\\.\\s*", "", trimmed))
    return(list(verdict = "Disagree", explanation = explanation))
  }

  stop("Assessment must begin with exactly 'Agree.' or 'Disagree.'.", call. = FALSE)
}

extract_branch_dags <- function(dagwood_result) {
  branch_obj <- dagwood_result$DAGs.branch
  if (is.null(branch_obj) || is.null(branch_obj$DAG.branch.candidate)) {
    return(list())
  }

  as.list(branch_obj$DAG.branch.candidate)
}

extract_root_dag <- function(dagwood_result, parsed_dag_text) {
  root_candidate <- dagwood_result$DAG.root
  if (!is.null(root_candidate) && length(root_candidate) > 0) {
    return(root_candidate)
  }

  parsed_dag_text
}
