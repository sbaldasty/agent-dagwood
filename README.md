# Agent Dagwood

Agent Dagwood is an R package that launches a Shiny app that leverages LLMs and Dagwood for causal-identification review.

## Workflow
1. The user provides a causal inference scenario in natural language, or selects an example from a drop down list

2. A LLM identifies the treatment and outcome variables, and generates a causal graph

3. Dagwood inspects the causal graph and identifies any necessary assumptions

4. The LLM agrees or disagrees with each assumption, and explains its reasoning

5. The user receives the entire review in a digestible format

## Installation

Agent Dagwood lives on [R-Universe](https://sbaldasty.r-universe.dev/agentdagwood), and can be installed as follows.

```r
install.packages("agentdagwood", repos = c("https://sbaldasty.r-universe.dev", "https://cloud.r-project.org"))
```

Its source code is available on [GitHub](https://github.com/sbaldasty/agent-dagwood/stargazers) under a liberal open source license.

## LLM setup

Agent Dagwood requires a LLM to work properly. Currently the only supported options are Gemini and local ollama models. The prompts in the app are tuned for Gemini. Configure a provider with environment variables before launch.

### Gemini

```bash
export LLM_PROVIDER=gemini
export GEMINI_API_KEY=your_api_key_here
export GEMINI_MODEL=gemini-2.5-flash
```

### Local with Ollama

```bash
export LLM_PROVIDER=local
export LOCAL_API_URL=http://localhost:11434/api/chat
export LOCAL_MODEL=deepseek-r1:1.5b
```

## Launch

You can start the app from within an R session.

```r
library(agentdagwood)
run_app()
```

## Troubleshooting

While most issues are LLM-related, Agent Dagwood is still quite new. Feel free to submit any bugs you discover on the GitHub issue tracker.

| Symptom | Likely cause | Fix |
|---|---|---|
| `GEMINI_API_KEY is required when LLM_PROVIDER=gemini` | Missing key | Set `GEMINI_API_KEY` in the shell before launching R |
| Local provider call failed | Ollama/local endpoint is down or wrong URL | Verify `LOCAL_API_URL` and that the service is reachable |
| `Model output could not be parsed` | LLM returned malformed graph text | Retry analysis or switch model/provider |
| Empty assumption assessments | Slow provider response or provider error | Check status text in-app and provider logs |
