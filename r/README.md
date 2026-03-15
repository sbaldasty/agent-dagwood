# R Subproject (DAGWOOD)

This folder contains the R example for DAGWOOD.

## Files

- `scripts/dwcli.R`: Simple DAGWOOD example using `dagwood` and `ggdag`

## Setup

Run these once in R to install required packages:

```r
install.packages("dagwood")
install.packages("ggdag")
```

Optional, but recommended for reproducibility:

```r
install.packages("renv")
renv::init()
renv::snapshot()
```

## Run

From the repository root:

```bash
Rscript r/scripts/dwcli.R
```

Or from an R session:

```r
source("r/scripts/dwcli.R")
```

## Notes

- Keep `install.packages(...)` calls in setup docs, not runtime scripts.
- If you adopt `renv`, teammates can restore with `renv::restore()`.
