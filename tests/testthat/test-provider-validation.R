test_that("validate_provider_config rejects unsupported providers", {
  expect_error(
    agentdagwood:::validate_provider_config(provider = "unknown"),
    "Unsupported LLM_PROVIDER"
  )
})

test_that("validate_provider_config accepts none provider", {
  cfg <- agentdagwood:::validate_provider_config(provider = "none")

  expect_equal(cfg$provider, "none")
})

test_that("validate_provider_config requires gemini key", {
  expect_error(
    agentdagwood:::validate_provider_config(provider = "gemini", gemini_api_key = ""),
    "GEMINI_API_KEY is required"
  )
})

test_that("validate_provider_config local path validation", {
  cfg <- agentdagwood:::validate_provider_config(provider = "local", local_api_url = "http://localhost:11434/api/chat")
  expect_equal(cfg$provider, "local")

  expect_error(
    agentdagwood:::validate_provider_config(provider = "local", local_api_url = ""),
    "LOCAL_API_URL is required"
  )
})

test_that("call_llm returns parseable DAG fallback for conv_dag prompt", {
  response <- agentdagwood:::call_llm(
    agentdagwood:::conv_dag_instr,
    "Scenario text",
    config = agentdagwood:::validate_provider_config(provider = "none")
  )
  parsed <- agentdagwood:::parse_llm_graph(response)

  expect_equal(parsed$exposure, "treatment")
  expect_equal(parsed$outcome, "outcome")
  expect_match(parsed$dag, "treatment -> outcome", fixed = TRUE)
})

test_that("call_llm returns assessment-safe fallback for other prompts", {
  response <- agentdagwood:::call_llm(
    agentdagwood:::eval_assumption_instr,
    "Assumption text",
    config = agentdagwood:::validate_provider_config(provider = "none")
  )
  parsed <- agentdagwood:::parse_assessment_response(response)

  expect_equal(parsed$verdict, "Agree")
  expect_match(parsed$explanation, "No LLM provider is configured")
})
