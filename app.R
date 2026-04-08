library(httr2)
library(jsonlite)
library(dagwood)
library(ggdag)

conv_dag_instr <-
  "The user will present a causal inference scenario. Interpret the scenario and
  format your response as follows.:
  ```
  [treatment_variable]
  [outcome_variable]
  [cause_1] -> [effect_1]
  [cause_2] -> [effect_2]
  ...
  ```
  Variable names should not suggest any particulardirection the variable may
  take, and should not contain spaces."

eval_assumption_instr <-
  "The following is a causal graph the user is contemplating. Each line
  is a causal relationship in the form 'cause -> effect'.
  The graph may be incomplete and may not include all relevant variables.
  The user will present an assumption, and your task is to evaluate that
  assumption using the graph and any other relevant knowledge you have, even
  about variables that are not included. Begin your response with 'Agree.' or
  'Disagree.' Then explain your reasoning."

eval_graph_instr <-
  "The user will send you the name of a treatment variable, the name of an
  outcome variable, and a causal graph they are contemplating. Each line in the
  graph is a causal relationship in the form 'cause -> effect'.
  The graph may be incomplete and may not include all relevant variables.
  List and explain any dubious assumptions the graph is making that could
  threaten the validity of a causal inference based on this graph."

# Study 1: Rainfall, Economic Growth, and Civil Conflict in Sub-Saharan Africa
dag_prompt_iv_1 <-
  "A large body of research examines whether poor economic 
  conditions cause civil conflict. Because conflict and economic 
  performance are jointly determined, establishing causality is 
  difficult with observational data alone. Several influential 
  studies address this endogeneity by using rainfall variation as 
  an instrumental variable for economic growth in agrarian 
  economies, reasoning that rainfall shocks affect crop yields and 
  thereby GDP growth. Using panel data for dozens of sub-Saharan 
  African countries from the early 1980s through the 2000s, these 
  studies instrument GDP growth with contemporaneous and lagged 
  rainfall and find that a five-percentage-point decline in growth 
  raises the probability of civil war onset by roughly ten to 
  twelve percentage points.\n
  The instrument is motivated by the observation that in economies 
  heavily reliant on rain-fed agriculture, rainfall fluctuations 
  are a powerful predictor of year-to-year income variation. The 
  first-stage relationship is strong, with F-statistics comfortably 
  above conventional thresholds. Since weather is determined by 
  atmospheric processes rather than human decisions, it is 
  plausibly exogenous to the political and social factors that 
  drive conflict. The authors control for country fixed effects, 
  year effects, and a battery of time-varying covariates.\n
  The reduced-form relationship between rainfall and conflict is 
  also strong and negative: more rainfall is associated with less 
  conflict. The studies have been enormously influential, spawning 
  a large literature on climate and political violence. They have 
  been extended to sub-national data in multiple countries, and the 
  basic finding that adverse economic shocks increase conflict risk 
  has been replicated in many settings. The rainfall instrument has 
  subsequently been adopted as a workhorse tool for instrumenting 
  economic variables in developing-country contexts across many 
  different outcome domains."

# Study 2: Police Hiring, Electoral Cycles, and the Deterrent Effect of
# Law Enforcement
dag_prompt_iv_2 <-
  "Does hiring more police reduce crime? This question is difficult 
  to answer because police levels and crime rates are jointly 
  determined: cities with rising crime tend to hire more officers, 
  creating a positive correlation that masks any deterrent effect. 
  A well-known study addresses this reverse-causality problem using 
  an instrumental variables approach. The study instruments police 
  force size with the timing of mayoral and gubernatorial elections, 
  reasoning that incumbent politicians hire additional officers in 
  election years to appear tough on crime, and that the electoral 
  calendar is exogenous to crime trends. Using a panel of 59 large 
  U.S. cities from 1970 to 1992, the author finds that increases in 
  police force size reduce violent crime by roughly 3 to 10 
  percent.\n
  The logic of the instrument is that election-year hiring reflects 
  the political incentives of incumbents rather than a response to 
  contemporaneous crime conditions. The IV estimates imply 
  substantially larger deterrent effects than OLS, which the author 
  attributes to the attenuation bias introduced by simultaneity. In 
  a follow-up study responding to criticism of the election-cycle 
  instrument, the author proposes an alternative instrument: the 
  number of firefighters employed by the city, arguing that 
  firefighter hiring tracks the fiscal capacity available for all 
  municipal hiring, including police.\n
  The study has been widely cited in the economics of crime 
  literature and in policy debates about police funding. It 
  established a template for using quasi-experimental variation to 
  estimate the causal effect of policing. The election-cycle 
  instrument is appealing because it is rooted in a clear 
  institutional mechanism, and the firefighter instrument draws on 
  fiscal co-movement between public safety agencies. Subsequent 
  researchers have extended this line of work using other sources of 
  variation, such as federal policing grants and city-level natural 
  experiments."

# Study 3: Settler Mortality, Colonial Institutions, and
# Long-Run Economic Development
dag_prompt_iv_3 <-
  "Why are some countries rich and others poor? A landmark study 
  proposes that differences in institutional quality, specifically 
  the protection of property rights, are a fundamental cause of 
  cross-country income differences. Because institutions are 
  endogenous to economic performance, the authors address this 
  identification challenge with an instrumental variable: the 
  mortality rate of European soldiers and settlers in former 
  colonies during the 17th to 19th centuries. The argument is that 
  in colonies where Europeans faced high mortality, they established 
  extractive institutions oriented toward resource extraction rather 
  than settlement. Where mortality was low, Europeans settled in 
  large numbers and transplanted inclusive institutions with checks 
  on government power. These institutional patterns persisted and 
  continue to shape economic outcomes today.\n
  Using a sample of 64 former European colonies, the authors show a 
  strong first-stage relationship between settler mortality and 
  current institutional quality as measured by an index of 
  expropriation risk. The second-stage estimates indicate that 
  institutional quality has a large causal effect on GDP per capita. 
  The exclusion restriction is defended on the grounds that 
  historical settler mortality reflected diseases like malaria and 
  yellow fever that primarily affected non-immune Europeans and had 
  little direct bearing on the current economic environment. The 
  authors present robustness checks controlling for geographic 
  variables such as latitude, climate, and natural resource 
  endowments.\n
  The study has had enormous intellectual impact and is among the 
  most cited papers in economics. It provided the empirical backbone 
  for the broader argument, developed across several companion papers, 
  that political institutions are the deep cause of long-run 
  development. The settler mortality instrument has been used in 
  dozens of subsequent studies examining the effects of institutions 
  on outcomes ranging from financial development to public health. 
  The paper received further recognition when its authors were 
  awarded the Nobel Prize in Economics in 2024."

# Study 4: Physician Prescribing Preferences and Comparative Effectiveness of
# Antipsychotic Medications
dag_prompt_iv_4 <-
  "Evaluating the comparative effectiveness of medications using 
  observational data is challenging because treatment assignment 
  reflects patient characteristics that also predict outcomes. In 
  comparative effectiveness research on antipsychotic medications, 
  patients prescribed newer atypical antipsychotics tend to differ 
  systematically from those prescribed older typical antipsychotics 
  in ways that are difficult to fully measure. Several studies 
  address this confounding by using physician prescribing preference 
  as an instrumental variable. The instrument is constructed by 
  measuring each physician's historical tendency to prescribe one 
  medication class over another, and this preference is used as a 
  source of quasi-random variation in treatment assignment. The 
  reasoning is that which physician a patient sees is often 
  determined by scheduling logistics rather than by the patient's 
  clinical profile.\n
  These studies find that physician preference strongly predicts 
  individual treatment assignment: patients of physicians who 
  generally favor atypical antipsychotics are substantially more 
  likely to receive them. The IV estimates of the treatment effect 
  often differ meaningfully from naive regression estimates, which 
  the authors interpret as evidence that unmeasured confounding 
  biases ordinary analyses. The instrument's validity rests on the 
  assumption that conditional on measured covariates, physician 
  preference affects outcomes only through treatment assignment and 
  not through other channels.\n
  The preference-based instrument has become one of the most popular 
  approaches in pharmacoepidemiological research more broadly, 
  applied to surgical techniques, medical devices, and many drug 
  classes. It has been endorsed as a practical alternative to 
  randomized trials in settings where randomization is infeasible or 
  unethical. The approach is attractive because it leverages 
  naturally occurring variation in practice patterns across 
  clinicians, requires no special data collection beyond what is 
  available in administrative claims databases, and can be applied 
  in large samples with high statistical power."

# Study 5: Proximity to High-Level Neonatal Intensive Care and Infant Mortality
# among Premature Births
dag_prompt_iv_5 <-
  "Whether premature infants benefit from delivery at hospitals with 
  high-level neonatal intensive care units (NICUs) is an important 
  question in health economics and neonatology. Comparing outcomes 
  between infants delivered at high- versus low-level NICUs is 
  complicated by selection, because sicker babies are more likely to 
  be sent to high-level units, creating a positive correlation between 
  NICU level and mortality that confounds naive comparisons. A 
  prominent study addresses this using differential travel time as an 
  instrumental variable. The instrument is the excess travel time from 
  a mother's zip code to the nearest high-level NICU relative to the 
  nearest hospital of any type. Mothers who live closer to high-level 
  NICUs are more likely to deliver there, and this geographic 
  variation is arguably exogenous to individual health status.\n
  Using birth and death certificate data on over 190,000 premature 
  births in Pennsylvania from 1995 to 2005, the authors show that 
  excess travel time strongly predicts delivery at a high-level NICU. 
  The IV estimates suggest that delivery at a high-level NICU prevents 
  roughly 6 deaths per 1,000 premature births. These estimates are 
  substantially different from those obtained by naive comparisons, 
  underscoring the importance of accounting for selection. The 
  identification strategy is motivated by the plausible argument that, 
  within a given risk stratum, proximity to a high-level NICU is as 
  good as randomly assigned.\n
  The study has been influential in neonatal policy discussions and 
  has been used to argue for regionalized systems of perinatal care. 
  The travel-time instrument has been adopted in many other health 
  services research applications, including studies of trauma center 
  access, cardiac surgery, and cancer treatment. The methodological 
  contribution of the study is also significant: it has become a 
  standard teaching example in IV estimation courses and textbooks, 
  and the data have been re-analyzed by several groups exploring 
  refinements to standard IV methodology."


# Provider selection:
# - Set LLM_PROVIDER=local (default) to use a local Ollama-compatible endpoint.
# - Set LLM_PROVIDER=gemini to use Google Gemini via API key.
llm_provider <- tolower(Sys.getenv("LLM_PROVIDER", "gemini"))
local_api_url <- Sys.getenv("LOCAL_API_URL", "http://localhost:11434/api/chat")
local_model_name <- Sys.getenv("LOCAL_MODEL", "deepseek-r1:1.5b")
gemini_model_name <- Sys.getenv("GEMINI_MODEL", "gemini-2.5-flash")
gemini_api_key <- Sys.getenv("GEMINI_API_KEY", "")

call_llm <- function(system_prompt, user_prompt) {
  if (llm_provider == "local") {
    output <- request(local_api_url) |>
      req_method("POST") |>
      req_body_raw(toJSON(list(
        model = local_model_name,
        messages = list(
          list(role = "system", content = system_prompt),
          list(role = "user", content = user_prompt)
        ),
        stream = FALSE
      ), auto_unbox = TRUE)) |>
      req_perform()
    json <- output |> resp_body_json()
    return(json$message$content)
  }

  if (llm_provider == "gemini") {
    if (nchar(gemini_api_key) == 0) {
      stop("GEMINI_API_KEY is required when LLM_PROVIDER=gemini")
    }

    gemini_url <- paste0(
      "https://generativelanguage.googleapis.com/v1beta/models/",
      gemini_model_name,
      ":generateContent"
    )

    output <- request(gemini_url) |>
      req_url_query(key = gemini_api_key) |>
      req_method("POST") |>
      req_body_raw(toJSON(list(
        systemInstruction = list(parts = list(list(text = system_prompt))),
        contents = list(
          list(role = "user", parts = list(list(text = user_prompt)))
        )
      ), auto_unbox = TRUE)) |>
      req_perform()

    json <- output |> resp_body_json()
    parts <- json$candidates[[1]]$content$parts
    texts <- vapply(parts, function(part) part$text %||% "", character(1))
    return(paste(texts[nzchar(texts)], collapse = "\n"))
  }

  stop("Unsupported LLM_PROVIDER. Use 'local' or 'gemini'.")
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

# Get a causal graph from a LLM
response <- call_llm(conv_dag_instr, dag_prompt_iv_5)
print(response)

# Parse out the response
lines <- strsplit(response, "\n", fixed = TRUE)[[1]]
lines <- gsub("\r", "", lines)
exposure <- lines[1]
outcome <- lines[2]
dag <- paste(lines[-(1:2)], collapse = "\n")

# Feed graph into Dagwood and generate assumptions
result <- dagwood(dag, exposure, outcome)
summary_lines <- strsplit(result$Summary, "\n", fixed = TRUE)[[1]]
summary_lines <- trimws(summary_lines)
assumptions <- summary_lines[startsWith(summary_lines, ".")]
assumptions <- sub("^\\.\\s*", "", assumptions)

sink("dagwood_", append = FALSE, split = FALSE)
print("CAUSAL GRAPH:")
print(paste("Exposure:", exposure))
print(paste("Outcome:", outcome))
print(paste("Structure:", dag))

# Have the LLM come up with dubious assumptions on its own
user_prompt <- paste("\nHere is the treatment variable: ", exposure,
                     "\nHere is the outcome variable: ", outcome,
                     "\nHere is the graph: ", dag)
response <- call_llm(eval_graph_instr, user_prompt)
print("LLM-GENERATED ASSUMPTIONS:")
print(response)

# Have the LLM evaluate each Dagwood assumption
for (assumption in assumptions) {
  sys_prompt <- paste("Here is the graph: ", eval_assumption_instr, dag)
  response <- call_llm(sys_prompt, assumption)
  print(paste("DAGWOOD ASSUMPTION: ", assumption))
  print(response)
}
sink()
