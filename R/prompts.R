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
  'Disagree.' Then explain your reasoning concisely."

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
