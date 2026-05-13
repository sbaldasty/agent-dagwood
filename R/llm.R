validate_provider_config <- function(
    provider = tolower(Sys.getenv("LLM_PROVIDER", "none")),
    gemini_api_key = Sys.getenv("GEMINI_API_KEY", ""),
    gemini_model = Sys.getenv("GEMINI_MODEL", "gemini-2.5-flash"),
    local_api_url = Sys.getenv("LOCAL_API_URL", "http://localhost:11434/api/chat"),
    local_model = Sys.getenv("LOCAL_MODEL", "deepseek-r1:1.5b")) {
  provider <- tolower(trimws(provider))
  if (!provider %in% c("none", "local", "gemini")) {
    stop("Unsupported LLM_PROVIDER. Use 'none', 'local', or 'gemini'.", call. = FALSE)
  }

  if (provider == "gemini" && !nzchar(trimws(gemini_api_key))) {
    stop("GEMINI_API_KEY is required when LLM_PROVIDER=gemini", call. = FALSE)
  }

  if (provider == "local" && !nzchar(trimws(local_api_url))) {
    stop("LOCAL_API_URL is required when LLM_PROVIDER=local", call. = FALSE)
  }

  list(
    provider = provider,
    gemini_api_key = gemini_api_key,
    gemini_model = gemini_model,
    local_api_url = local_api_url,
    local_model = local_model
  )
}

default_llm_response <- function(system_prompt) {
  if (identical(trimws(system_prompt), trimws(conv_dag_instr))) {
    return(paste(
      "treatment",
      "outcome",
      "treatment -> outcome",
      sep = "\n"
    ))
  }

  "Agree. No LLM provider is configured, so this placeholder response was returned."
}

call_llm <- function(system_prompt, user_prompt, config = validate_provider_config()) {
  if (identical(config$provider, "none")) {
    return(default_llm_response(system_prompt))
  }
  if (identical(config$provider, "local")) {
    req <- httr2::request(config$local_api_url) |>
      httr2::req_method("POST") |>
      httr2::req_body_raw(jsonlite::toJSON(list(
        model = config$local_model,
        messages = list(
          list(role = "system", content = system_prompt),
          list(role = "user", content = user_prompt)
        ),
        stream = FALSE
      ), auto_unbox = TRUE))

    response <- tryCatch(
      httr2::req_perform(req),
      error = function(e) {
        stop(
          paste0(
            "Local provider call failed. Check LOCAL_API_URL and endpoint availability. ",
            "Details: ",
            conditionMessage(e)
          ),
          call. = FALSE
        )
      }
    )

    json <- httr2::resp_body_json(response)
    message <- json$message$content %||% ""
    if (!nzchar(trimws(message))) {
      stop("Local provider returned an empty response body.", call. = FALSE)
    }
    return(message)
  }

  gemini_url <- paste0(
    "https://generativelanguage.googleapis.com/v1beta/models/",
    config$gemini_model,
    ":generateContent"
  )

  req <- httr2::request(gemini_url) |>
    httr2::req_url_query(key = config$gemini_api_key) |>
    httr2::req_method("POST") |>
    httr2::req_body_raw(jsonlite::toJSON(list(
      systemInstruction = list(parts = list(list(text = system_prompt))),
      contents = list(
        list(role = "user", parts = list(list(text = user_prompt)))
      )
    ), auto_unbox = TRUE))

  response <- tryCatch(
    httr2::req_perform(req),
    error = function(e) {
      stop(
        paste0(
          "Gemini provider call failed. Check GEMINI_API_KEY and model configuration. ",
          "Details: ",
          conditionMessage(e)
        ),
        call. = FALSE
      )
    }
  )

  json <- httr2::resp_body_json(response)
  candidates <- json$candidates %||% list()
  if (length(candidates) == 0) {
    stop("Gemini response did not contain any candidates.", call. = FALSE)
  }

  parts <- candidates[[1]]$content$parts %||% list()
  if (length(parts) == 0) {
    stop("Gemini response did not contain message parts.", call. = FALSE)
  }

  texts <- vapply(parts, function(part) part$text %||% "", character(1))
  combined <- paste(texts[nzchar(texts)], collapse = "\n")
  if (!nzchar(trimws(combined))) {
    stop("Gemini response text was empty.", call. = FALSE)
  }

  combined
}
