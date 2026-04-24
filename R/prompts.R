conv_dag_instr <-
  "The user will present a causal inference scenario. Interpret the scenario and
  format your response as follows:
  ```
  [treatment_variable]
  [outcome_variable]
  [cause_1] -> [effect_1]
  [cause_2] -> [effect_2]
  ...
  ```
  Variable names should not suggest any particular direction the variable may
  take, and should not contain spaces."

eval_assumption_instr <-
  "The following is a causal graph the user is contemplating. Each line
  is a causal relationship in the form 'cause -> effect'.
  The graph may be incomplete and may not include all relevant variables.
  The user will present an assumption, and your task is to evaluate that
  assumption using the graph and any other relevant knowledge you have, even
  about variables that are not included. Begin your response with 'Agree.' or
  'Disagree.' Then explain your reasoning concisely in plain text."

eval_graph_instr <-
  "You will be presented with a scenario. Implicit in the scenario is a
  treatment variable, an outcome variable, and a causal graph. You must report
  on any dubious implicit or explicit assumptions, such as the absence of
  certain confounders or the directionality of causal arrows, whose falsehood
  would call into question the causal effect of the treatment variable on the
  outcome variable. List and explain each such assumption separately."

get_example_prompts <- function() {
  list(
    "Custom input" = "",
    "Rainfall and Civil Conflict" = read_extdata_text("conflict.txt"),
    "Police Hiring and Crime" = read_extdata_text("hiring.txt"),
    "Settler Mortality and Development" = read_extdata_text("settlers.txt"),
    "Physician Preference and Antipsychotics" = read_extdata_text("prefs.txt"),
    "NICU Proximity and Infant Mortality" = read_extdata_text("nicu.txt")
  )
}
