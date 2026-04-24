# agentdagwood

agentdagwood is an R package that launches a Shiny app for causal-identification review.

The app:
1. Accepts free-form causal inference scenario text.
2. Uses an LLM to convert the scenario into a DAG edge list.
3. Runs Dagwood to identify assumptions.
4. Asks the LLM to assess each Dagwood assumption and explain the reasoning.

## Install

### R-universe (recommended)

```r
install.packages("agentdagwood", repos = c("https://sbaldasty.r-universe.dev", "https://cloud.r-project.org"))
```

### From source

```r
install.packages("pak")
pak::pak("sbaldasty/agent-dagwood")
```

## Launch

```r
library(agentdagwood)
run_app()
```

## LLM provider setup

Configure one provider with environment variables before launch.

### Gemini

```bash
export LLM_PROVIDER=gemini
export GEMINI_API_KEY=your_api_key_here
export GEMINI_MODEL=gemini-2.5-flash
```

### Local (Ollama-compatible)

```bash
export LLM_PROVIDER=local
export LOCAL_API_URL=http://localhost:11434/api/chat
export LOCAL_MODEL=deepseek-r1:1.5b
```

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `GEMINI_API_KEY is required when LLM_PROVIDER=gemini` | Missing key | Set `GEMINI_API_KEY` in the shell before launching R |
| Local provider call failed | Ollama/local endpoint is down or wrong URL | Verify `LOCAL_API_URL` and that the service is reachable |
| `Model output could not be parsed` | LLM returned malformed graph text | Retry analysis or switch model/provider |
| Empty assumption assessments | Slow provider response or provider error | Check status text in-app and provider logs |

## Included examples

The five IV handout scenarios are bundled inside the package under `inst/extdata` and loaded in the app dropdown.
