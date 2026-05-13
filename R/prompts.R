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
  "The following is a DAGWOOD Root DAG where each line represents a relationship
  of the form 'cause -> effect'.
  You will be presented an assumption from DAGWOOD that must hold in order for
  causal inferences to be valid. Use the graph and your subject matter expertise
  to evaluate the assumption. Begin your response with 'Agree.' or 'Disagree.'
  Then explain your reasoning, ideally in a short paragraph or two. For
  instance, if the assumption asserts the nonexistence of a common cause, either
  defend that or propose one; or if the assumption asserts the nonexistence of a
  pathway, either defend that or propose one."

blank_scenario <- "[Custom]"

example_scenarios <- function() {
  c(
    setNames(list(""), blank_scenario),
    list(
      "Rainfall and Civil Conflict" = read_scenario("conflict.txt"),
      "Police Hiring and Crime" = read_scenario("hiring.txt"),
      "Settler Mortality and Development" = read_scenario("settlers.txt"),
      "Physician Preference and Antipsychotics" = read_scenario("prefs.txt"),
      "NICU Proximity and Infant Mortality" = read_scenario("nicu.txt")
    )
  )
}
