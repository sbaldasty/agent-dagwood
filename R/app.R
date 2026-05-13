build_ui <- function(example_prompts) {
  shiny::fluidPage(
    shiny::titlePanel("Agent Dagwood"),
    shiny::fluidRow(
      shiny::column(
        width = 12,
        shiny::p("Provide a causal inference scenario in natural language, or select an example from the drop down list. When you Analyze, a LLM will identify your treatment and outcome variables, and generate a causal graph. Using the causal graph, Dagwood will generate assumptions that must hold for a causal analysis to be valid, and the LLM will offer its opinion about each assumption.")
      )
    ),
    shiny::fluidRow(
      shiny::column(
        width = 12,
        shiny::selectInput(
          "example_prompt",
          "Load example scenario",
          choices = names(example_prompts),
          selected = blank_scenario,
          width = "100%"
        ),
        shiny::textAreaInput("scenario_input", "Scenario text", value = example_prompts[[blank_scenario]], rows = 10, width = "100%"),
        shiny::actionButton("analyze_btn", "Analyze", class = "btn-primary"),
        shiny::actionButton("clear_btn", "Clear"),
        shiny::h4("Run Status"),
        shiny::verbatimTextOutput("status_text"),
        shiny::uiOutput("graph_summary_section"),
        shiny::uiOutput("assumptions_section")
      )
    )
  )
}

build_server <- function(example_prompts) {
  function(input, output, session) {
    state <- shiny::reactiveValues(
      status = "Idle",
      graph_data = NULL,
      assumptions = character(),
      evaluations = character(),
      verdicts = character(),
      run_id = 0
    )

    shiny::observeEvent(input$example_prompt, {
      selected <- example_prompts[[input$example_prompt]]
      if (!is.null(selected)) {
        shiny::updateTextAreaInput(session, "scenario_input", value = selected)
      }
    })

    shiny::observeEvent(input$clear_btn, {
      state$run_id <- state$run_id + 1
      shiny::updateTextAreaInput(session, "scenario_input", value = "")
      state$status <- "Cleared input"
      state$graph_data <- NULL
      state$assumptions <- character()
      state$evaluations <- character()
      state$verdicts <- character()
    })

    shiny::observeEvent(input$analyze_btn, {
      capture_error <- function(expr) {
        tryCatch(
          list(ok = TRUE, value = expr),
          error = function(e) list(ok = FALSE, message = conditionMessage(e))
        )
      }

      user_text <- trimws(input$scenario_input)
      if (!nzchar(user_text)) {
        state$status <- "Please provide scenario text before analyzing."
        return()
      }

      config_result <- capture_error(validate_provider_config())
      if (!isTRUE(config_result$ok)) {
        state$status <- paste("Error:", config_result$message)
        return()
      }
      config <- config_result$value

      state$run_id <- state$run_id + 1
      current_run <- state$run_id
      state$status <- "Starting analysis..."
      state$graph_data <- NULL
      state$assumptions <- character()
      state$evaluations <- character()
      state$verdicts <- character()

      result_result <- capture_error(analyze_scenario(user_text, config = config))
      if (!isTRUE(result_result$ok)) {
        state$status <- paste("Error:", result_result$message)
      } else {
        result <- result_result$value
        if (!identical(current_run, state$run_id)) {
          return()
        }

        state$graph_data <- list(
          parsed = result$parsed,
          root_dag = result$root_dag,
          branch_dags = result$branch_dags
        )
        state$assumptions <- result$assumptions
        state$evaluations <- rep("", length(result$assumptions))
        state$verdicts <- rep("", length(result$assumptions))

        total <- length(result$assumptions)
        if (total == 0) {
          state$status <- "Completed. No Dagwood assumptions returned."
          return()
        }

        state$status <- paste("Evaluating assumption 1 of", total)

        set_assumption_result <- function(idx, verdict, explanation) {
          if (idx <= length(state$evaluations) && idx <= length(state$verdicts)) {
            state$verdicts[idx] <- verdict
            state$evaluations[idx] <- explanation
          }
        }

        set_assumption_error <- function(idx, message) {
          set_assumption_result(idx, "Error", paste("Error:", message))
          state$status <- paste("Error:", message)
        }

        evaluate_next <- function(idx) {
          if (!identical(current_run, shiny::isolate(state$run_id))) {
            return()
          }

          assumptions_snapshot <- shiny::isolate(state$assumptions)
          graph_snapshot <- shiny::isolate(state$graph_data)
          if (is.null(graph_snapshot)) {
            return()
          }

          total_local <- length(assumptions_snapshot)
          if (idx > total_local) {
            shiny::isolate({
              state$status <- "Completed"
            })
            return()
          }

          shiny::isolate({
            state$status <- paste("Evaluating assumption", idx, "of", total_local)
          })
          assumption <- assumptions_snapshot[idx]
          dag_text <- graph_snapshot$parsed$dag

          parsed_assessment <- tryCatch(
            {
              assessment <- evaluate_single_assumption(assumption, dag_text, config = config)
              parse_assessment_response(assessment)
            },
            error = function(e) e
          )

          if (inherits(parsed_assessment, "error")) {
            shiny::isolate(set_assumption_error(idx, parsed_assessment$message))
            return()
          }

          shiny::isolate({
            set_assumption_result(idx, parsed_assessment$verdict, parsed_assessment$explanation)
          })

          later::later(function() evaluate_next(idx + 1), delay = 0)
        }

        later::later(function() evaluate_next(1), delay = 0)
      }
    })

    output$status_text <- shiny::renderText({
      state$status
    })

    output$graph_summary_section <- shiny::renderUI({
      shiny::req(state$graph_data)
      shiny::tagList(
        shiny::h4("Graph Summary"),
        shiny::uiOutput("graph_summary"),
        shiny::plotOutput("root_dag_plot")
      )
    })

    output$graph_summary <- shiny::renderUI({
      shiny::req(state$graph_data)
      assumption_count <- length(state$assumptions)
      assumption_label <- if (assumption_count == 1) "assumption" else "assumptions"
      summary_md <- paste0(
        "The **exposure** variable is `",
        state$graph_data$parsed$exposure,
        "`, and the **outcome** variable is `",
        state$graph_data$parsed$outcome,
        "`. Dagwood generated **",
        assumption_count,
        "** ",
        assumption_label,
        "."
      )
      shiny::HTML(markdown::markdownToHTML(text = summary_md, fragment.only = TRUE))
    })

    output$root_dag_plot <- shiny::renderPlot({
      shiny::req(state$graph_data)
      ggdag::ggdag(state$graph_data$root_dag) +
        ggdag::geom_dag_edges(edge_colour = "#333333") +
        ggdag::geom_dag_node(colour = "#2C6E49") +
        ggdag::geom_dag_text(colour = "#FFFFFF") +
        ggdag::geom_dag_label(colour = "#000000") +
        ggdag::theme_dag()
    })

    output$assumptions_section <- shiny::renderUI({
      shiny::req(state$graph_data)
      shiny::tagList(
        shiny::h4("Dagwood Assumptions With LLM Assessments"),
        shiny::uiOutput("assumptions_ui")
      )
    })

    output$assumptions_ui <- shiny::renderUI({
      shiny::req(state$graph_data)

      assumptions <- state$assumptions
      branch_dags <- state$graph_data$branch_dags %||% list()
      verdicts <- state$verdicts %||% character()
      completed_idx <- which(nzchar(trimws(verdicts)))

      if (length(assumptions) == 0) {
        return(shiny::tags$p("Dagwood did not return any assumptions for this graph."))
      }

      if (length(completed_idx) == 0) {
        return(NULL)
      }

      cards <- lapply(completed_idx, function(i) {
        plot_id <- paste0("branch_dag_plot_", i)
        verdict_id <- paste0("assumption_verdict_", i)
        assessment_id <- paste0("assumption_assessment_", i)

        if (i <= length(branch_dags)) {
          local({
            idx <- i
            pid <- plot_id
            output[[pid]] <- shiny::renderPlot({
              dag_candidate <- state$graph_data$branch_dags[[idx]]
              ggdag::ggdag(dag_candidate) +
                ggdag::geom_dag_edges(edge_colour = "#333333") +
                ggdag::geom_dag_node(colour = "#2C6E49") +
                ggdag::geom_dag_text(colour = "#FFFFFF") +
                ggdag::geom_dag_label(colour = "#000000") +
                ggdag::theme_dag()
            }, height = 260)
          })
        }

        local({
          idx <- i
          vid <- verdict_id
          output[[vid]] <- shiny::renderUI({
            verdict_value <- state$verdicts[idx] %||% ""
            is_error <- identical(verdict_value, "Error")
            verdict_color <- if (is_error) {
              "#b00020"
            } else if (identical(verdict_value, "Agree")) {
              "#1b5e20"
            } else {
              "#8b0000"
            }

            shiny::tags$span(
              verdict_value,
              style = paste0("color:", verdict_color, "; font-weight:700;")
            )
          })
        })

        local({
          idx <- i
          aid <- assessment_id
          output[[aid]] <- shiny::renderUI({
            assessment <- state$evaluations[idx] %||% ""

            shiny::tags$div(
              shiny::HTML(markdown::markdownToHTML(text = assessment, fragment.only = TRUE)),
              style = "white-space:pre-wrap;"
            )
          })
        })

        shiny::tags$div(
          style = "border:1px solid #d9d9d9; border-radius:8px; padding:12px; margin-bottom:10px;",
          shiny::tags$div(
            style = "display:flex; justify-content:space-between; align-items:center;",
            shiny::tags$strong(sprintf("Assumption %d", i)),
            shiny::uiOutput(verdict_id)
          ),
          shiny::tags$div(
            style = "display:flex; gap:12px; align-items:flex-start; margin-top:8px;",
            shiny::tags$div(
              style = "flex:1; min-width:280px;",
              shiny::tags$p(assumptions[i], style = "margin-top:0px; margin-bottom:8px;"),
              shiny::uiOutput(assessment_id)
            ),
            shiny::tags$div(
              style = "flex:1; min-width:280px;",
              if (i <= length(branch_dags)) {
                shiny::plotOutput(plot_id, width = "100%")
              } else {
                shiny::tags$p("No branch DAG available for this assumption.")
              }
            )
          )
        )
      })

      do.call(shiny::tagList, cards)
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
  app <- shiny::shinyApp(
    ui = build_ui(example_prompts),
    server = build_server(example_prompts)
  )
  shiny::runApp(app, launch.browser = launch.browser, ...)
}
