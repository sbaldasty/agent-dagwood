test_that("parse_llm_graph parses fenced response", {
  response <- paste(
    "```",
    "treat",
    "outcome",
    "z -> treat",
    "treat -> outcome",
    "```",
    sep = "\n"
  )

  parsed <- agentdagwood:::parse_llm_graph(response)

  expect_equal(parsed$exposure, "treat")
  expect_equal(parsed$outcome, "outcome")
  expect_match(parsed$dag, "z -> treat")
  expect_match(parsed$dag, "treat -> outcome")
})

test_that("parse_assessment_response validates prefix", {
  agree <- agentdagwood:::parse_assessment_response("Agree. This is reasonable")
  disagree <- agentdagwood:::parse_assessment_response("Disagree. There is confounding")

  expect_equal(agree$verdict, "Agree")
  expect_equal(disagree$verdict, "Disagree")
  expect_error(
    agentdagwood:::parse_assessment_response("Maybe. It depends."),
    "Assessment must begin"
  )
})
