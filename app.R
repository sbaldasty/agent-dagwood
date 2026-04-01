library(httr2)
library(jsonlite)
library(dagwood)
library(ggdag)

conv_dag_instr <- "
  The user will present a causal inference scenario. Interpret the scenario and
  Format your response as follows:
  The first line consists of the treatment variable.
  The second line consists of the outcome variable.
  Any subsequent lines should consist of causal relationships in the form
  'cause -> effect'."

# TODO Externalize the prompt
dag_prompt <- "People go outside on holidays. Parades happen on holidays."

# TODO Externalize the API URL
api_url <- "http://localhost:11434/api/chat"

# TODO Externalize the model name and version
model_name <- "deepseek-r1:1.5b"

# Get a causal graph from a LLM
# output <- request(api_url) |>
#   req_method("POST") |>
#   req_body_raw(toJSON(list(
#     model = model_name,
#     messages = list(
#       list(role = "system", content = conv_dag_instr),
#       list(role = "user", content = dag_prompt)
#     ),
#     stream = FALSE
#   ), auto_unbox = TRUE)) |>
#   req_perform()
# json <- output |> resp_body_json()
# response <- json$message$content
# print(response)

# TEMPORARY
response <- "Chocolate
Alzheimers
Chocolate -> Alzheimers
Chocolate <- Education -> Alzheimers
Chocolate -> CV
CV -> Alzheimers"

lines <- strsplit(response, "\n", fixed = TRUE)[[1]]
lines <- gsub("\r", "", lines)

exposure <- lines[1]
outcome <- lines[2]
dag <- paste(lines[-(1:2)], collapse = "\n")

result <- dagwood(dag, exposure, outcome)
assumptions <- paste(result$Summary[-(1:2)], collapse = "\n")
print(assumptions)
#branches <- result$DAGs.branch
#ggdag(branches$DAG.branch.candidate[1]) + theme_dag()
