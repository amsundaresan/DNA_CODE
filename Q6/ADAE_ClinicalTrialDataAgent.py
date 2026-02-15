"""
ClinicalTrialDataAgent
Fully column-agnostic AI assistant for ADAE dataset.
"""

import os

# Suppress PyTorch/transformers warnings from LangChain dependencies (only OpenAI API used)
os.environ.setdefault("TRANSFORMERS_VERBOSITY", "error")
os.environ.setdefault("TRANSFORMERS_NO_ADVISORY_WARNINGS", "1")

import json
import re
import sys
import pandas as pd
from typing import Dict, Any, Tuple

from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import JsonOutputParser


# ============================================================
# 1️⃣ Load ADAE
# ============================================================

DATA_PATH = "data/adae.csv"
PHARMAVERSE_AE_RDA_URL = "https://raw.githubusercontent.com/pharmaverse/pharmaversesdtm/main/data/ae.rda"


def _load_adae() -> Tuple[pd.DataFrame, bool]:
    """Load ADAE: use data/adae.csv if present, else download and read pharmaverse ae.rda.
    Returns (dataframe, used_pharmaverse).
    """
    if os.path.exists(DATA_PATH):
        return pd.read_csv(DATA_PATH), False
    # Fallback: fetch ae.rda from pharmaverse
    import tempfile
    import urllib.request
    try:
        with urllib.request.urlopen(PHARMAVERSE_AE_RDA_URL, timeout=30) as resp:
            rda_bytes = resp.read()
    except Exception as e:
        raise FileNotFoundError(
            f"Neither {DATA_PATH} nor pharmaverse ae.rda could be used. "
            f"Local file missing and download failed: {e}"
        ) from e
    try:
        import pyreadr
    except ImportError:
        raise ImportError(
            "Reading pharmaverse ae.rda requires pyreadr. Install with: pip install pyreadr"
        ) from None
    with tempfile.NamedTemporaryFile(suffix=".rda", delete=False) as f:
        f.write(rda_bytes)
        tmp_path = f.name
    try:
        obj = pyreadr.read_r(tmp_path)
        if not obj:
            raise ValueError("ae.rda contains no readable objects.")
        adae_df = next(iter(obj.values()))
        if not isinstance(adae_df, pd.DataFrame):
            raise TypeError("ae.rda did not contain a DataFrame.")
        return adae_df, True
    finally:
        try:
            os.unlink(tmp_path)
        except OSError:
            pass


adae, _used_pharmaverse = _load_adae()
adae.columns = adae.columns.str.upper()
if _used_pharmaverse:
    print(
        "Note: Using pharmaverse default AE data (ae.rda). Local data/adae.csv was not found.",
        file=sys.stderr,
    )


# ============================================================
# 2️⃣ Official Column Descriptions (from ae.R)
# ============================================================

COLUMN_DESCRIPTIONS = {
    "STUDYID": "Study Identifier",
    "DOMAIN": "Domain Abbreviation",
    "USUBJID": "Unique Subject Identifier",
    "AESEQ": "Sequence Number",
    "AESPID": "Sponsor-Defined Identifier",
    "AETERM": "Reported Term for the Adverse Event",
    "AELLT": "Lowest Level Term",
    "AELLTCD": "Lowest Level Term Code",
    "AEDECOD": "Dictionary-Derived Term",
    "AEPTCD": "Preferred Term Code",
    "AEHLT": "High Level Term",
    "AEHLTCD": "High Level Term Code",
    "AEHLGT": "High Level Group Term",
    "AEHLGTCD": "High Level Group Term Code",
    "AEBODSYS": "Body System or Organ Class",
    "AEBDSYCD": "Body System or Organ Class Code",
    "AESOC": "Primary System Organ Class",
    "AESOCCD": "Primary System Organ Class Code",
    "AESEV": "Severity/Intensity",
    "AESER": "Serious Event",
    "AEACN": "Action Taken with Study Treatment",
    "AEREL": "Causality",
    "AEOUT": "Outcome of Adverse Event",
    "AESCAN": "Involves Cancer",
    "AESCONG": "Congenital Anomaly or Birth Defect",
    "AESDISAB": "Persist or Significant Disability/Incapacity",
    "AESDTH": "Results in Death",
    "AESHOSP": "Requires or Prolongs Hospitalization",
    "AESLIFE": "Is Life Threatening",
    "AESOD": "Occurred with Overdose",
    "AEDTC": "Date/Time of Collection",
    "AESTDTC": "Start Date/Time of Adverse Event",
    "AEENDTC": "End Date/Time of Adverse Event",
    "AESTDY": "Study Day of Start of Adverse Event",
    "AEENDY": "Study Day of End of Adverse Event"
}

VALID_COLUMNS = list(COLUMN_DESCRIPTIONS.keys())


# ============================================================
# 3️⃣ LLM Setup
# ============================================================

SYSTEM_PROMPT = f"""
You are a clinical trial data assistant.

Your task:
Parse the user's question into structured JSON describing how to filter the ADAE dataset.
If the question has TWO OR MORE criteria (e.g. severity AND a specific AE term), return ONE filter per criterion.
All filters are combined with AND (subject must match every filter).

Return ONLY valid JSON in this format:

{{{{
  "filters": [
    {{{{
      "target_column": "COLUMN_NAME",
      "filter_operator": "equals | contains | greater_than | less_than",
      "filter_value": "VALUE"
    }}}},
    ...
  ]
}}}}

Rules:
- For "who has severe events involving Pruritus?" use two filters: one for AESEV = "SEVERE", one for AETERM or AEDECOD contains "Pruritus".
- target_column for each filter MUST be one of:
{VALID_COLUMNS}

- Use column descriptions to determine correct column(s).
- Extract the correct filter value from the question for each criterion.
- For Yes/No flags, use "Y" or "N".
- For numeric fields (e.g., AESEQ, AESTDY, AEENDY), use numeric comparison operators.
- For text fields (e.g., AETERM, AEDECOD, AESEV), use "contains" unless exact match is clearly requested.
- Use "equals" for severity (AESEV) when the question specifies a single severity (e.g. severe, mild).
- If the question has only ONE criterion, return "filters" with a single element.
- Do NOT explain anything.
- Only return JSON.
"""

_openai_api_key = os.getenv("OPENAI_API_KEY")
if not _openai_api_key or not str(_openai_api_key).strip():
    print(
        "OPENAI_API_KEY is not set. To use this agent, set your OpenAI API key:\n\n"
        "  Option 1 - Export in your shell (bash/zsh):\n"
        "    export OPENAI_API_KEY='your-api-key-here'\n\n"
        "  Option 2 - In the same terminal before running:\n"
        "    OPENAI_API_KEY='your-api-key-here' python ADAE_ClinicalTrialDataAgent.py\n\n"
        "Get an API key at: https://platform.openai.com/api-keys",
        file=sys.stderr,
    )
    sys.exit(1)

llm = ChatOpenAI(
    model="gpt-4o-mini",
    temperature=0,
    api_key=_openai_api_key,
)

prompt = ChatPromptTemplate.from_messages([
    ("system", SYSTEM_PROMPT),
    ("human", "{question}")
])

parser = JsonOutputParser()
llm_chain = prompt | llm | parser

# Fallback: when no results, ask LLM for alternative filter_value from actual column values
ALTERNATIVE_VALUE_PROMPT = """No rows matched for column "{column}" ({column_description}) with value "{original_value}".

Here are actual values that appear in this column (sample):
{sample_values}

Suggest ONE alternative filter value that is the closest match or spelling variant (e.g. UK vs US spelling, MedDRA term) for "{original_value}". Pick from the list above if possible.
Return ONLY valid JSON: {{ "filter_value": "your_suggested_value" }}
"""

alternative_parser = JsonOutputParser()
alternative_prompt = ChatPromptTemplate.from_messages([
    ("human", ALTERNATIVE_VALUE_PROMPT),
])
llm_alternative_chain = alternative_prompt | llm | alternative_parser


# ============================================================
# 4️⃣ Apply Filter Safely (single filter)
# ============================================================

def _apply_single_filter(
    target_column: str,
    filter_operator: str,
    filter_value: Any,
    df: pd.DataFrame,
) -> pd.DataFrame:
    """Apply one filter to a dataframe. Returns filtered dataframe."""
    if target_column not in df.columns:
        raise ValueError(f"Invalid column selected: {target_column}")

    series = df[target_column]

    # Numeric columns
    if pd.api.types.is_numeric_dtype(series):
        val = float(filter_value)
        if filter_operator == "greater_than":
            return df[series > val]
        if filter_operator == "less_than":
            return df[series < val]
        if filter_operator == "equals":
            return df[series == val]
        raise ValueError(f"Invalid operator for numeric column: {filter_operator}")

    # Text columns
    series = series.astype(str)
    val_upper = str(filter_value).upper()
    if filter_operator == "equals":
        return df[series.str.upper() == val_upper]
    if filter_operator == "contains":
        return df[series.str.upper().str.contains(re.escape(val_upper), na=False, regex=True)]
    raise ValueError(f"Invalid operator for text column: {filter_operator}")


def apply_filter(parsed_json: Dict[str, Any], df: pd.DataFrame) -> Dict[str, Any]:
    """
    Apply one or more filters (AND logic).
    parsed_json: either { "filters": [ { target_column, filter_operator, filter_value }, ... ] }
                 or legacy { "target_column", "filter_operator", "filter_value" }.
    """
    # Normalize to list of filters
    if "filters" in parsed_json:
        filters = list(parsed_json["filters"])
    else:
        # Legacy single-filter format
        filters = [parsed_json]

    if not filters:
        raise ValueError("At least one filter is required.")

    filtered = df
    for f in filters:
        filtered = _apply_single_filter(
            f["target_column"],
            f["filter_operator"],
            f["filter_value"],
            filtered,
        )

    unique_subjects = filtered["USUBJID"].unique().tolist()
    return {
        "count_unique_subjects": len(unique_subjects),
        "subjects": unique_subjects,
        "filtered_df": filtered,
    }


# ============================================================
# 5️⃣ Main Agent
# ============================================================

def _get_sample_values_for_column(column: str, df: pd.DataFrame, max_values: int = 300) -> str:
    """Get a sample of distinct values from the column for LLM fallback."""
    series = df[column].dropna().astype(str).str.strip()
    uniq = series.unique().tolist()
    if len(uniq) <= max_values:
        return "\n".join(uniq)
    return "\n".join(uniq[:max_values]) + f"\n... and {len(uniq) - max_values} more"


def _normalize_parsed(parsed: Dict[str, Any]) -> Dict[str, Any]:
    """Ensure parsed has 'filters' list (support legacy single-filter format)."""
    if "filters" in parsed and isinstance(parsed["filters"], list):
        return parsed
    if "target_column" in parsed:
        return {"filters": [parsed]}
    raise ValueError("Parsed JSON must have 'filters' list or legacy target_column/filter_operator/filter_value.")


def clinical_trial_data_agent(question: str):

    parsed = llm_chain.invoke({"question": question})
    parsed = _normalize_parsed(parsed)
    result = apply_filter(parsed, adae)
    alternative_value_used = None  # e.g. "Pruritus" -> "PRURITUS" when fallback was used

    # If no results, try alternative filter_value for the first text filter
    filters = list(parsed["filters"])
    if result["count_unique_subjects"] == 0 and filters:
        for i, f in enumerate(filters):
            col = f.get("target_column")
            if col not in adae.columns or pd.api.types.is_numeric_dtype(adae[col]):
                continue
            sample_values = _get_sample_values_for_column(col, adae)
            try:
                alt = llm_alternative_chain.invoke({
                    "column": col,
                    "column_description": COLUMN_DESCRIPTIONS.get(col, col),
                    "original_value": f["filter_value"],
                    "sample_values": sample_values,
                })
                suggested = (alt or {}).get("filter_value")
                if suggested and str(suggested).strip():
                    filters_retry = [*filters]
                    filters_retry[i] = {**f, "filter_value": str(suggested).strip()}
                    parsed_retry = {"filters": filters_retry}
                    result_retry = apply_filter(parsed_retry, adae)
                    if result_retry["count_unique_subjects"] > 0:
                        result = result_retry
                        parsed = parsed_retry
                        alternative_value_used = suggested
                        break
            except Exception:
                continue
        else:
            pass  # no alternative helped

    return {
        "question": question,
        "parsed_filter": parsed,
        "result": result,
        "filtered_df": result["filtered_df"],
        "alternative_value_used": alternative_value_used,
    }


# ============================================================
# 6️⃣ CLI
# ============================================================

if __name__ == "__main__":

    print("ClinicalTrialDataAgent Ready")

    while True:
        q = input("\nAsk a question (or type exit): ")

        if q.lower() == "exit":
            break

        response = clinical_trial_data_agent(q)

        # Table: USUBJID and key AE columns
        filtered_df = response["filtered_df"]
        table_cols = ["USUBJID", "AETERM", "AELLT", "AESEV", "AESTDY", "AESEQ", "AEDECOD"]
        table_cols = [c for c in table_cols if c in filtered_df.columns]
        print("\n" + "=" * 60)
        print(f"  {response['question']}")
        if response.get("alternative_value_used"):
            print("  (No exact AETERM match; used closest value from data: \"{}\")".format(response["alternative_value_used"]))
        print("=" * 60)
        if filtered_df.empty:
            print("  (No matching records)")
        else:
            table_df = filtered_df[table_cols].drop_duplicates() # drop duplicates to avoid duplicate rows or rows with the same value for all columns
            max_rows = 50
            display_df = table_df if len(table_df) <= max_rows else table_df.head(max_rows)
            print(display_df.to_string(index=False))
            if len(table_df) > max_rows:
                print(f"  ... and {len(table_df) - max_rows} more rows")
        print("=" * 60)

        # Sorted list of unique subjects
        if not filtered_df.empty and "USUBJID" in filtered_df.columns:
            unique_subjects = sorted(filtered_df["USUBJID"].drop_duplicates().tolist())
            print(f"\n  Unique subjects (sorted): {len(unique_subjects)}")
            print("-" * 60)
            for s in unique_subjects:
                print(f"  {s}")
            print("-" * 60)

        # JSON (exclude non-serializable dataframe)
       # out = {k: v for k, v in response.items() if k != "filtered_df"}
       # if "result" in out and "filtered_df" in out["result"]:
       #  out["result"] = {k: v for k, v in out["result"].items() if k != "filtered_df"}
       # print("\nFull response (JSON):")
       # print(json.dumps(out, indent=2))
