# DNA Code Challenge

A clinical trial and SDTM/ADaM-focused codebase containing R packages, R scripts for domain creation and analysis, a FastAPI service for AE querying, and an AI-powered clinical trial data agent.

---

## Repository structure

```
DNA_CODE/
├── README.md                 # This file
│
├── Q1/                       # R package: descriptive statistics
│   └── descriptiveStats/
│
├── Q2/                       # SDTM DS domain creation
│   ├── create_ds_domain.R
│   └── metadata/
│
├── Q3/                       # ADaM ADSL creation
│   └── create_adsl.R
│
├── Q4/                       # TEAE summary, listings, and visualizations
│   ├── 01_create_ae_summary_table..R
│   ├── 02_create_visualizations.R
│   ├── 03_create_listings.R
│   ├── TEAE_summarytable.html
│   ├── TEAE_listings.html
│   ├── TEAE_Severity_by_arm.png
│   └── Top10_ae_incidence_exactCI.png
│
├── Q5/                       # Clinical Trial Data REST API (FastAPI)
│   ├── main.py
│   ├── requirements.txt
│   └── data/
│       └── adae.csv
│
└── Q6/                       # AI Clinical Trial Data Agent
    ├── ADAE_ClinicalTrialDataAgent.py
    ├── test_agent_queries.py
    ├── requirements.txt
    └── data/                 # optional: adae.csv (else pharmaverse used)
```

---

## Q1 — descriptiveStats (R package)

**Purpose:** R package providing robust summary statistics for numeric vectors (mean, median, mode, Q1, Q3, IQR) with consistent handling of `NA`, empty vectors, and edge cases.

### Contents

| Path | Description |
|------|-------------|
| `R/` | Core functions: `calc_mean.R`, `calc_median.R`, `calc_mode.R`, `calc_iqr.R`, `calc_q1.R`, `calc_q3.R` |
| `man/` | R documentation (roxygen2-generated `.Rd` files) |
| `tests/testthat/` | testthat tests for each function (`test-calc_mean.R`, `test-calc_median.R`, etc.) |
| `DESCRIPTION` | Package metadata, dependencies (testthat, rmarkdown) |
| `NAMESPACE` | Exports and `importFrom(stats, ...)` |
| `NEWS.md` | Changelog |
| `README.md` | Package-specific install and usage |

### How to run

```r
# Install (from repo root or Q1)
devtools::install("Q1/descriptiveStats")

# Run tests
devtools::test(pkg = "Q1/descriptiveStats")

# Use
library(descriptiveStats)
calc_mean(c(1, 2, NA, 4))
calc_median(c(1, 2, 3, 4))
calc_iqr(c(1, 2, 3, 4))
```

### Dependencies

- R (≥ 4.0); **testthat** (≥ 3.0), **rmarkdown** (Suggests). No extra R package imports in code (uses base + `stats`).

---

## Q2 — SDTM DS domain

**Purpose:** Create the SDTM Disposition (DS) domain from pharmaverse raw data using `sdtm.oak` mapping and controlled terminology.

### Contents

| Path | Description |
|------|-------------|
| `create_ds_domain.R` | Builds DS with STUDYID, DOMAIN, USUBJID, DSSEQ, DSTERM, DSDECOD, DSCAT, VISITNUM, VISIT, DSDTC, DSSTDTC, DSSTDY |
| `metadata/sdtm_ct.csv` | Controlled terminology (saved from pharmaverse examples) |

### How to run

- Open and run `create_ds_domain.R` in R with working directory set to `Q2/`.
- Requires: **sdtm.oak**, **pharmaverseraw**, **dplyr**, **lubridate** (and `metadata/sdtm_ct.csv` in place).

---

## Q3 — ADaM ADSL creation

**Purpose:** Build the Subject-Level Analysis Dataset (ADSL) from pharmaverse SDTM (DM, DS, EX, AE, LB) using **admiral** and **pharmaversesdtm**.

### Contents

| Path | Description |
|------|-------------|
| `create_adsl.R` | Derives ADSL: treatment vars (TRT01P, TRT01A), exposure dates (TRTSDTM, TRTEDTM), flags (SAFFL, ITTFL), and other ADSL variables per admiral conventions |

### How to run

- Run `create_adsl.R` from `Q3/` in R.
- Requires: **admiral**, **dplyr**, **pharmaversesdtm**, **lubridate**, **stringr**.

---

## Q4 — TEAE summary, listings, and visualizations

**Purpose:** Treatment-Emergent Adverse Event (TEAE) summary table, listings, and severity/body-system visualizations using **pharmaverseadam**, **gtsummary**, and **ggplot2**.

### Contents

| Path | Description |
|------|-------------|
| `01_create_ae_summary_table..R` | Hierarchical AE summary by TRT01A (gtsummary); outputs `TEAE_summarytable.html` |
| `02_create_visualizations.R` | AE severity by treatment (bar), top 10 AE incidence with exact CI; outputs PNGs |
| `03_create_listings.R` | TEAE listing (screen failures removed); outputs `TEAE_listings.html` |
| `TEAE_summarytable.html` | Generated summary table |
| `TEAE_listings.html` | Generated listing |
| `TEAE_Severity_by_arm.png` | AE severity distribution by treatment arm (stacked bar) |
| `Top10_ae_incidence_exactCI.png` | Top 10 TEAEs with Clopper–Pearson exact 95% CI |

### How to run

- Run the scripts in order from `Q4/` (e.g. `01_...`, then `02_...`, then `03_...`).
- Requires: **dplyr**, **gtsummary**, **ggplot2**, **lubridate**, **pharmaverseadam**, **pharmaversesdtm** (for DS in listings).

---

## Q5 — Clinical Trial Data API (FastAPI)

**Purpose:** REST API to query adverse-event data: filter by severity and/or treatment arm, and get subject-level risk scores.

### Contents

| Path | Description |
|------|-------------|
| `main.py` | FastAPI app: `GET /`, `POST /ae-query`, `GET /subject-risk/{subject_id}` |
| `requirements.txt` | fastapi, uvicorn, pandas, pydantic |
| `data/adae.csv` | Input AE dataset (expected columns include USUBJID, AESEV; ACTARM optional) |

### How to run

```bash
cd Q5
pip install -r requirements.txt
uvicorn main:app --reload
```

- API: <http://127.0.0.1:8000>  
- Docs: <http://127.0.0.1:8000/docs>

### Endpoints

- **GET /** — Health check.
- **POST /ae-query** — Body: `{ "severity": ["SEVERE"], "treatment_arm": "Placebo" }` (optional). Returns matching record count, unique subject count, and subject list.
- **GET /subject-risk/{subject_id}** — Returns risk score and category (Low/Medium/High) for a subject.

---

## Q6 — AI Clinical Trial Data Agent

**Purpose:** Column-agnostic AI assistant that turns natural-language questions about the ADAE dataset into filters and returns matching subjects. Supports multi-criteria questions (e.g. “Who had severe events involving Pruritus?”). Uses OpenAI (LangChain) and optional pharmaverse AE data fallback.

**Requirements:** **`OPENAI_API_KEY`** must be set in the environment (e.g. `export OPENAI_API_KEY='your-key'`). Without it, the agent exits with instructions to set the key.

### Contents

| Path | Description |
|------|-------------|
| `ADAE_ClinicalTrialDataAgent.py` | Main agent: loads ADAE (local CSV or pharmaverse ae.rda), parses questions to JSON filters, applies filters (AND), optional spelling/value fallback |
| `test_agent_queries.py` | Runs three example queries: “Who died?”, “Who had fractures?”, “Who had severe events involving cancer?” |
| `requirements.txt` | pandas, langchain-openai, langchain-core, pyreadr (for pharmaverse .rda fallback) |
| `data/adae.csv` | Optional. If missing, downloads and uses pharmaverse ae.rda and notifies the user. |

### How to run

Set **`OPENAI_API_KEY`** (required), then run the agent or test script:

```bash
cd Q6
export OPENAI_API_KEY='your-key'   # required
pip install -r requirements.txt
python ADAE_ClinicalTrialDataAgent.py    # Interactive CLI
# or
python test_agent_queries.py             # Run the three example queries
```

- If `data/adae.csv` is not present, the script uses the pharmaverse default AE file and prints a note to stderr.

---

## Quick reference

| Folder | Language | Main output / use |
|--------|----------|--------------------|
| **Q1** | R | Installable package; summary stats and tests |
| **Q2** | R | DS domain dataset (run script) |
| **Q3** | R | ADSL dataset (run script) |
| **Q4** | R | HTML summary table, listing, and plots |
| **Q5** | Python | FastAPI server (uvicorn) |
| **Q6** | Python | CLI agent + test script (**OPENAI_API_KEY** required) |

---

## Notes for GitHub

- The repo **.gitignore** excludes R/Python artifacts (e.g. `.Rproj.user`, `.Rhistory`, `.RData`, `.DS_Store`). Only tracked files are shown in the structure above.
- **Q5** and **Q6** can use `data/adae.csv`; **Q6** can fall back to pharmaverse ae.rda if the file is missing.
- R components assume pharmaverse packages are available from CRAN/other declared sources where referenced.
