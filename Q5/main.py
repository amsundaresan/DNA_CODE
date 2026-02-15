from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import pandas as pd
import os

# ============================================================
# 1️⃣ App Initialization
# ============================================================

app = FastAPI(
    title="Clinical Trial Data API",
    version="1.0.0"
)

# ============================================================
# 2️⃣ Load Dataset
# ============================================================

# Path relative to this file so it works from Q5 or project root
_here = os.path.dirname(os.path.abspath(__file__))
DATA_PATH = os.path.join(_here, "data", "adae.csv")

if not os.path.exists(DATA_PATH):
    raise FileNotFoundError("adae.csv not found.")

df = pd.read_csv(DATA_PATH)
df.columns = df.columns.str.upper()

# Ensure required columns exist (ACTARM optional - add placeholder if missing)
REQUIRED_COLUMNS = ["USUBJID", "AESEV"]
for col in REQUIRED_COLUMNS:
    if col not in df.columns:
        raise ValueError(f"Missing required column: {col}")
HAS_ACTARM = "ACTARM" in df.columns
if not HAS_ACTARM:
    df["ACTARM"] = ""


# ============================================================
# 3️⃣ Root Endpoint
# ============================================================

@app.get("/")
def root():
    return {"message": "Clinical Trial Data API is running"}


# ============================================================
# 4️⃣ Dynamic Filtering Endpoint
# ============================================================

class AEQueryRequest(BaseModel):
    severity: Optional[List[str]] = None
    treatment_arm: Optional[str] = None


@app.post("/ae-query")
def ae_query(request: AEQueryRequest):

    filtered_df = df.copy()

    # Filter by severity (AESEV)
    if request.severity:
        severity_values = [s.upper() for s in request.severity]
        filtered_df = filtered_df[
            filtered_df["AESEV"].str.upper().isin(severity_values)
        ]

    # Filter by treatment arm (ACTARM) only when dataset has real ACTARM data
    if request.treatment_arm and HAS_ACTARM:
        arm_vals = filtered_df["ACTARM"].astype(str).str.upper()
        filtered_df = filtered_df[arm_vals == request.treatment_arm.upper()]

    unique_subjects = filtered_df["USUBJID"].unique().tolist()

    return {
        "matching_record_count": len(filtered_df),
        "unique_subject_count": len(unique_subjects),
        "subjects": unique_subjects
    }


# ============================================================
# 5️⃣ Subject Risk Score Endpoint
# ============================================================

SEVERITY_WEIGHTS = {
    "MILD": 1,
    "MODERATE": 3,
    "SEVERE": 5
}


@app.get("/subject-risk/{subject_id}")
def subject_risk(subject_id: str):

    subject_df = df[df["USUBJID"] == subject_id]

    if subject_df.empty:
        raise HTTPException(
            status_code=404,
            detail="Subject not found."
        )

    risk_score = 0

    for sev in subject_df["AESEV"].astype(str).str.upper():
        risk_score += SEVERITY_WEIGHTS.get(sev, 0)

    # Determine risk category
    if risk_score < 5:
        risk_category = "Low"
    elif 5 <= risk_score < 15:
        risk_category = "Medium"
    else:
        risk_category = "High"

    return {
        "subject_id": subject_id,
        "risk_score": risk_score,
        "risk_category": risk_category
    }
