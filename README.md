# agent-dagwood

Single-page Shiny app that:
1. Accepts free-form causal inference scenario text from the user.
2. Uses an LLM to convert the scenario into a causal graph.
3. Sends that graph to Dagwood to extract identification assumptions.
4. Asks the LLM to agree or disagree with each Dagwood assumption and explain why.

All results are shown on one page.

## Requirements

- R 4.3+
- R packages:
	- shiny
	- httr2
	- jsonlite
	- dagwood
	- ggdag

Install packages:

```r
install.packages(c("shiny", "httr2", "jsonlite", "dagwood", "ggdag"))
```

## LLM Configuration

Set provider and credentials using environment variables.

### Option A: Gemini

```bash
export LLM_PROVIDER=gemini
export GEMINI_API_KEY=your_api_key_here
# Optional override:
export GEMINI_MODEL=gemini-2.5-flash
```

### Option B: Local (Ollama-compatible)

```bash
export LLM_PROVIDER=local
export LOCAL_API_URL=http://localhost:11434/api/chat
export LOCAL_MODEL=deepseek-r1:1.5b
```

## Run

From the repository root:

```bash
Rscript app.R
```

Or from an interactive R session:

```r
source("app.R")
```

This launches a Shiny page with:
- Example scenario selector
- Scenario text area input
- Analyze button
- In-page outputs for graph summary, Dagwood assumptions, and LLM assessments

## Notes

- If `LLM_PROVIDER=gemini`, `GEMINI_API_KEY` is required.
- If the LLM response is malformed (missing treatment/outcome/edges), the app surfaces a parse error instead of crashing.
- Assumption evaluation may take time because each assumption is sent to the LLM separately.
