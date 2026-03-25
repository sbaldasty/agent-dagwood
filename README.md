# agent-dagwood

Minimal mixed-language workspace for trying DAG-based workflows in Python and R.

## Project layout

- `main.py`: Python entrypoint (kept simple for now)
- `scripts/add_numbers.py`: Tool implementation for the function-calling demo
- `pyproject.toml`: Python package metadata and dependencies
- `r/scripts/dwcli.R`: Minimal DAGWOOD example script in R
- `r/README.md`: R environment setup and run instructions

## Why this layout

This repository keeps Python and R in one place while maintaining separate tooling:

- Python dependencies stay in `pyproject.toml`
- R dependencies are documented and can be managed with `renv`

This avoids dependency conflicts and makes it easy to split into separate repositories later if either side grows.

## Quick start

### Python

Install dependencies:

```bash
pip install -e .
```

Run local-first (Ollama):

```bash
ollama pull qwen2.5:7b-instruct
python main.py
```

Run with an explicit local model:

```bash
python main.py --models "ollama/llama3.2"
```

Compare multiple models in one pass:

```bash
python main.py --models "ollama/qwen2.5:7b-instruct,openai/gpt-4o-mini"
```

Use hosted providers by changing only model name + provider API key:

```bash
export OPENAI_API_KEY="..."
python main.py --models "openai/gpt-4o-mini"
```

```bash
export ANTHROPIC_API_KEY="..."
python main.py --models "anthropic/claude-3-5-haiku-latest"
```

Optional tool-calling demo loop:

```bash
python main.py --prompt "What is 12.4 + 9.6? Use a tool." --tool-demo
```

Environment variables used by the script:

- `MODEL`: default model if `--models` is not provided
- `MODELS`: comma-separated model list fallback
- `OLLAMA_BASE_URL`: defaults to `http://localhost:11434`
- `LITELLM_API_KEY`: optional generic key override

Basic run command:

```bash
python main.py
```

### R (DAGWOOD)

See setup and run commands in `r/README.md`.
