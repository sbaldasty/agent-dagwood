# agent-dagwood

Minimal mixed-language workspace for trying DAG-based workflows in Python and R.

## Project layout

- `main.py`: Python entrypoint (kept simple for now)
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

Run:

```bash
python main.py
```

### R (DAGWOOD)

See setup and run commands in `r/README.md`.
