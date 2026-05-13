evaluate_single_assumption <- function(assumption, dag, config = validate_provider_config()) {
  sys_prompt <- paste0(eval_assumption_instr, "\n\nGraph:\n", dag)
  call_llm(sys_prompt, assumption, config = config)
}

analyze_scenario <- function(user_text, config = validate_provider_config()) {
  dag_response <- call_llm(conv_dag_instr, user_text, config = config)
  parsed <- parse_llm_graph(dag_response)

  dagwood_result <- dagwood::dagwood(parsed$dag, parsed$exposure, parsed$outcome)
  assumptions <- extract_assumptions(dagwood_result)
  branch_dags <- extract_branch_dags(dagwood_result)
  root_dag <- extract_root_dag(dagwood_result, parsed$dag)

  list(
    parsed = parsed,
    assumptions = assumptions,
    evaluations = rep("", length(assumptions)),
    verdicts = rep("", length(assumptions)),
    branch_dags = branch_dags,
    root_dag = root_dag,
    dag_response = dag_response
  )
}
