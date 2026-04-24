build_ui <- function(example_prompts) {
  fluidPage(
    titlePanel("Agent Dagwood"),
    fluidRow(
      column(
        width = 12,
        p("Provide a causal inference scenario in natural language, or select an example from the drop down list. When you Analyze, a LLM will identify your treatment and outcome variables, and generate a causal graph. Using the causal graph, Dagwood will generate assumptions that must hold for a causal analysis to be valid, and the LLM will offer its opinion about each assumption.")
      )
    ),
    fluidRow(
      column(
        width = 5,
        selectInput(
          "example_prompt",
          "Load example scenario",
          choices = names(example_prompts),
          selected = blank_scenario,
          width = "100%"
        ),
        textAreaInput("scenario_input", "Scenario text", value = example_prompts[[blank_scenario]], rows = 20, width = "100%"),
        actionButton("analyze_btn", "Analyze", class = "btn-primary"),
        actionButton("clear_btn", "Clear")
      ),
      column(
        width = 7,
        h4("Run Status"),
        verbatimTextOutput("status_text"),
        h4("Graph Summary"),
        uiOutput("graph_summary"),
        plotOutput("root_dag_plot", height = 320),
        h4("Dagwood Assumptions With LLM Assessments"),
        uiOutput("assumptions_ui"),
        h4("LLM asked to find any dubious assumptions without Dagwood"),
        verbatimTextOutput("llm_assumptions_text")
      )
    )
  )
}

build_server <- function(example_prompts) {
  function(input, output, session) {
    state <- reactiveValues(
      status = "Idle",
      result = NULL,
      run_id = 0
    )

    observeEvent(input$example_prompt, {
      selected <- example_prompts[[input$example_prompt]]
      if (!is.null(selected)) {
        updateTextAreaInput(session, "scenario_input", value = selected)
      }
    })

    observeEvent(input$clear_btn, {
      state$run_id <- state$run_id + 1
      updateTextAreaInput(session, "scenario_input", value = "")
      state$status <- "Cleared input"
      state$result <- NULL
    })

    observeEvent(input$analyze_btn, {
      user_text <- trimws(input$scenario_input)
      if (!nzchar(user_text)) {
        state$status <- "Please provide scenario text before analyzing."
        return()
      }

      config <- tryCatch(
        validate_provider_config(),
        error = function(e) e
      )

      if (inherits(config, "error")) {
        state$status <- paste("Error:", config$message)
        showNotification(state$status, type = "error")
        return()
      }

      state$run_id <- state$run_id + 1
      current_run <- state$run_id
      state$status <- "Starting analysis..."
      state$result <- NULL

      withProgress(message = "Running analysis", value = 0, {
        result <- tryCatch(
          analyze_scenario(user_text, progress = function(value, detail) {
            setProgress(value = value, detail = detail)
            state$status <- detail
          }, config = config),
          error = function(e) e
        )

        if (inherits(result, "error")) {
          state$status <- paste("Error:", result$message)
          showNotification(state$status, type = "error")
        } else {
          if (!identical(current_run, state$run_id)) {
            return()
          }

          state$result <- result

          total <- length(result$assumptions)
          if (total == 0) {
            state$status <- "Completed. No Dagwood assumptions returned."
            return()
          }

          state$status <- paste("Evaluating assumption 1 of", total)

          evaluate_next <- function(idx) {
            if (!identical(current_run, isolate(state$run_id))) {
              return()
            }

            result_snapshot <- isolate(state$result)
            if (is.null(result_snapshot)) {
              return()
            }

            total_local <- length(result_snapshot$assumptions)
            if (idx > total_local) {
              isolate({
                state$status <- paste("Completed.", total_local, "Dagwood assumptions evaluated.")
              })
              return()
            }

            isolate({
              state$status <- paste("Evaluating assumption", idx, "of", total_local)
            })
            assumption <- result_snapshot$assumptions[idx]
            dag_text <- result_snapshot$parsed$dag

            assessment <- tryCatch(
              evaluate_single_assumption(assumption, dag_text, config = config),
              error = function(e) e
            )

            isolate({
              updated <- state$result
              if (!is.null(updated) && idx <= length(updated$evaluations) && idx <= length(updated$verdicts)) {
                if (inherits(assessment, "error")) {
                  updated$verdicts[idx] <- "Error"
                  updated$evaluations[idx] <- paste("Error:", assessment$message)
                } else {
                  parsed_assessment <- tryCatch(
                    parse_assessment_response(assessment),
                    error = function(e) e
                  )

                  if (inherits(parsed_assessment, "error")) {
                    updated$verdicts[idx] <- "Error"
                    updated$evaluations[idx] <- paste("Error:", parsed_assessment$message)
                  } else {
                    updated$verdicts[idx] <- parsed_assessment$verdict
                    updated$evaluations[idx] <- parsed_assessment$explanation
                  }
                }
                state$result <- updated
              }
            })

            later(function() evaluate_next(idx + 1), delay = 0)
          }

          later(function() evaluate_next(1), delay = 0)
        }
      })
    })

    output$status_text <- renderText({
      state$status
    })

    output$graph_summary <- renderUI({
      req(state$result)
      summary_md <- paste0(
        "The **exposure** variable is `",
        state$result$parsed$exposure,
        "`, and the **outcome** variable is `",
        state$result$parsed$outcome,
        "`."
      )
      HTML(markdown::markdownToHTML(text = summary_md, fragment.only = TRUE))
    })

    output$root_dag_plot <- renderPlot({
      req(state$result)
      ggdag(state$result$root_dag) +
        geom_dag_edges(edge_colour = "#333333") +
        geom_dag_node(colour = "#2C6E49") +
        geom_dag_text(colour = "#FFFFFF") +
        geom_dag_label(colour = "#000000") +
        theme_dag()
    })

    output$assumptions_ui <- renderUI({
      req(state$result)

      assumptions <- state$result$assumptions
      evaluations <- state$result$evaluations
      verdicts <- state$result$verdicts %||% rep("", length(assumptions))
      branch_dags <- state$result$branch_dags %||% list()

      if (length(assumptions) == 0) {
        return(tags$p("Dagwood did not return any assumptions for this graph."))
      }

      cards <- lapply(seq_along(assumptions), function(i) {
        plot_id <- paste0("branch_dag_plot_", i)
        assessment <- evaluations[i]
        verdict_value <- verdicts[i]
        pending <- !nzchar(trimws(verdict_value))
        is_error <- identical(verdict_value, "Error")
        verdict <- if (pending) "Pending" else verdict_value
        verdict_color <- if (pending) {
          "#616161"
        } else if (is_error) {
          "#b00020"
        } else if (identical(verdict_value, "Agree")) {
          "#1b5e20"
        } else {
          "#8b0000"
        }

        if (i <= length(branch_dags)) {
          local({
            idx <- i
            pid <- plot_id
            output[[pid]] <- renderPlot({
              dag_candidate <- state$result$branch_dags[[idx]]
              ggdag(dag_candidate) +
                geom_dag_edges(edge_colour = "#333333") +
                geom_dag_node(colour = "#2C6E49") +
                geom_dag_text(colour = "#FFFFFF") +
                geom_dag_label(colour = "#000000") +
                theme_dag()
            }, height = 260)
          })
        }

        tags$div(
          style = "border:1px solid #d9d9d9; border-radius:8px; padding:12px; margin-bottom:10px;",
          tags$div(
            style = "display:flex; justify-content:space-between; align-items:center;",
            tags$strong(sprintf("Assumption %d", i)),
            tags$span(verdict, style = paste0("color:", verdict_color, "; font-weight:700;"))
          ),
          tags$div(
            style = "display:flex; gap:12px; align-items:flex-start; margin-top:8px;",
            tags$div(
              style = "flex:1; min-width:280px;",
              tags$p(assumptions[i], style = "margin-top:0px; margin-bottom:8px;"),
              tags$div(
                if (pending) "Evaluating..." else HTML(markdown::markdownToHTML(text = assessment, fragment.only = TRUE)),
                style = "white-space:pre-wrap;"
              )
            ),
            tags$div(
              style = "flex:1; min-width:280px;",
              if (i <= length(branch_dags)) {
                plotOutput(plot_id, width = "100%")
              } else {
                tags$p("No branch DAG available for this assumption.")
              }
            )
          )
        )
      })

      do.call(tagList, cards)
    })

    output$llm_assumptions_text <- renderText({
      req(state$result)
      state$result$llm_assumptions
    })
  }
}

#' Launch the Agent Dagwood Shiny app
#'
#' @description Starts the packaged Shiny app for scenario-to-DAG analysis
#' and assumption evaluation.
#'
#' @param launch.browser Logical. Whether to open a browser automatically.
#' @param ... Additional arguments passed to [shiny::runApp()].
#'
#' @return Invisibly returns the running Shiny app object.
#' @export
run_app <- function(launch.browser = interactive(), ...) {
  example_prompts <- example_scenarios()
  app <- shinyApp(
    ui = build_ui(example_prompts),
    server = build_server(example_prompts)
  )
  runApp(app, launch.browser = launch.browser, ...)
}
