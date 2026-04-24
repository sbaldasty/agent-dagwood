evaluate_single_assumption <- function(assumption, dag, config = validate_provider_config()) {
  sys_prompt <- paste0(eval_assumption_instr, "\n\nGraph:\n", dag)
  call_llm(sys_prompt, assumption, config = config)
}

analyze_scenario <- function(user_text, progress = NULL, config = validate_provider_config()) {
  if (!is.null(progress)) progress(0.05, "Generating causal graph from scenario")
  dag_response <- call_llm(conv_dag_instr, user_text, config = config)
  parsed <- parse_llm_graph(dag_response)

  if (!is.null(progress)) progress(0.25, "Running Dagwood on generated graph")
  dagwood_result <- dagwood(parsed$dag, parsed$exposure, parsed$outcome)
  assumptions <- extract_assumptions(dagwood_result)
  branch_dags <- extract_branch_dags(dagwood_result)
  root_dag <- extract_root_dag(dagwood_result, parsed$dag)

  if (!is.null(progress)) progress(0.40, "Asking LLM for additional dubious assumptions")
  llm_assumptions <- call_llm(
    eval_graph_instr,
    paste(
      "Treatment:", parsed$exposure,
      "\nOutcome:", parsed$outcome,
      "\nGraph:\n", parsed$dag
    ),
    config = config
  )

  if (!is.null(progress)) progress(1, "Base analysis complete")

  list(
    parsed = parsed,
    assumptions = assumptions,
    evaluations = rep("", length(assumptions)),
    verdicts = rep("", length(assumptions)),
    branch_dags = branch_dags,
    root_dag = root_dag,
    llm_assumptions = llm_assumptions,
    dag_response = dag_response
  )
}
