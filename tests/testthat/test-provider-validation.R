test_that("validate_provider_config rejects unsupported providers", {
  expect_error(
    agentdagwood:::validate_provider_config(provider = "unknown"),
    "Unsupported LLM_PROVIDER"
  )
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
