library(httr2)
library(jsonlite)
library(dagwood)
library(ggdag)

conv_dag_instr <-
  "The user will present a causal inference scenario. Interpret the scenario and
  Format your response as follows:
  [treatment variable]
  [outcome variable]
  [cause1] -> [effect1]
  [cause2] -> [effect2]
  ..."

eval_assumption_instr <-
  "The following is a causal graph the user is contemplating. Each line
  is a causal relationship in the form 'cause -> effect'.
  The graph may be incomplete and may not include all relevant variables.
  The user will present an assumption, and your task is to evaluate that
  assumption using the graph and any other relevant knowledge you have, even
  about variables that are not included. Begin your response with 'Agree.' or
  'Disagree.' Then explain your reasoning.
  Here is the graph: "

# TODO Externalize the API URL
api_url <- "http://localhost:11434/api/chat"

# TODO Externalize the model name and version
model_name <- "deepseek-r1:1.5b"

# Get a causal graph from a LLM
output <- request(api_url) |>
  req_method("POST") |>
  req_body_raw(toJSON(list(
    model = model_name,
    messages = list(
      list(role = "system", content = conv_dag_instr),
      list(role = "user", content = dag_prompt)
    ),
    stream = FALSE
  ), auto_unbox = TRUE)) |>
  req_perform()
json <- output |> resp_body_json()
response <- json$message$content
print(response)

# Parse out the response
lines <- strsplit(response, "\n", fixed = TRUE)[[1]]
lines <- gsub("\r", "", lines)
exposure <- lines[1]
outcome <- lines[2]
dag <- paste(lines[-(1:2)], collapse = "\n")
print(paste("Exposure:", exposure))
print(paste("Outcome:", outcome))
print(paste("DAG:", dag))

# Feed graph into Dagwood and generate assumptions
result <- dagwood(dag, exposure, outcome)
summary_lines <- strsplit(result$Summary, "\n", fixed = TRUE)[[1]]
summary_lines <- trimws(summary_lines)
assumptions <- summary_lines[startsWith(summary_lines, ".")]
assumptions <- sub("^\\.\\s*", "", assumptions)

# Have the LLM evaluate each assumption
for (assumption in assumptions) {
  output <- request(api_url) |>
    req_method("POST") |>
    req_body_raw(toJSON(list(
      model = model_name,
      messages = list(
        list(role = "system", content = paste(eval_assumption_instr, dag)),
        list(role = "user", content = assumption)
      ),
      stream = FALSE
    ), auto_unbox = TRUE)) |>
    req_perform()
  json <- output |> resp_body_json()
  response <- json$message$content
  print(assumption)
  print(response)
}
