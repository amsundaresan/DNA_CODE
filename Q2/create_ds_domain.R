# Task: create the DS domain with the following variables 
# STUDYID, DOMAIN, USUBJID, DSSEQ, DSTERM, DSDECOD, DSCAT, VISITNUM, VISIT, DSDTC, DSSTDTC, DSSTDY

library(sdtm.oak) ## SDTM mapping functions
library(pharmaverseraw) # raw data 
library(dplyr)
library(lubridate)

#Read CT (controlled terminology)
   # 1)  #study_ct <- read.csv(
      #  system.file("raw_data/sdtm_ct.csv", package = "sdtm.oak")
      #)  #this doesn't have DS controlled term C66727
  # 2) study_ct <- read.csv("https://raw.githubusercontent.com/pharmaverse/examples/main/metadata/sdtm_ct.csv")

## saved version from github link above
study_ct <- read.csv("metadata/sdtm_ct.csv")

#### 
# ------------------------------------------------------------------------------
# SDTM variable derivation
# ------------------------------------------------------------------------------

## load raw data
ds_raw <- pharmaverseraw::ds_raw
ec_raw <- pharmaverseraw::ec_raw
dm_raw <- pharmaverseraw::dm_raw


# Derive oak_id_vars (unique internal id, raw source, patient number)
ds_raw <- ds_raw %>%
  generate_oak_id_vars(
    pat_var = "PATNUM",
    raw_src = "ds_raw"
  )

ec_raw <- ec_raw %>%
  generate_oak_id_vars(
    pat_var = "PATNUM",
    raw_src = "ec_raw"
  )

dm_raw <- dm_raw %>%
  generate_oak_id_vars(
    pat_var = "PATNUM",
    raw_src = "dm_raw"
  )

ref_date_conf_df <- tibble::tribble(
  ~raw_dataset_name, ~date_var,     ~time_var,      ~dformat,      ~tformat, ~sdtm_var_name,
  "ec_raw",       "IT.ECSTDAT", NA_character_, "dd-mmm-yyyy", NA_character_,     "RFXSTDTC",
  "ec_raw",       "IT.ECENDAT", NA_character_, "dd-mmm-yyyy", NA_character_,     "RFXENDTC",
  "ec_raw",       "IT.ECSTDAT", NA_character_, "dd-mmm-yyyy", NA_character_,      "RFSTDTC",
  "ec_raw",       "IT.ECENDAT", NA_character_, "dd-mmm-yyyy", NA_character_,      "RFENDTC",
  "dm_raw",            "IC_DT", NA_character_,  "mm/dd/yyyy", NA_character_,      "RFICDTC",
  "ds_raw",          "DSDTCOL",     "DSTMCOL",  "mm-dd-yyyy",         "H:M",     "RFPENDTC",
  "ds_raw",          "DEATHDT", NA_character_,  "mm/dd/yyyy", NA_character_,       "DTHDTC"
)

dm <- dm_raw %>%
  dplyr::mutate(
    STUDYID = dm_raw$STUDY,
    DOMAIN = "DM",
    USUBJID = paste0("01-", dm_raw$PATNUM) ) %>%
  # Derive RFSTDTC using oak_cal_ref_dates
  oak_cal_ref_dates(
    ds_in = .,
    der_var = "RFSTDTC",
    min_max = "min",
    ref_date_config_df = ref_date_conf_df,
    raw_source = list(
      ec_raw = ec_raw,
      ds_raw = ds_raw,
      dm_raw = dm_raw
    )
  )
  

# Derive topic variable
# Map DSTERM using assign_no_ct, raw_var=IT.DSTERM, tgt_var=DSTERM
ds <- assign_no_ct(
    raw_dat = ds_raw,
    raw_var = "IT.DSTERM",
    tgt_var = "DSTERM",
    id_vars = oak_id_vars()
  )

#Map identifier and timing variables
# Map DSDECOD using assign_ct, raw_var=IT.DSDECOD, tgt_var=DSDECOD
#ct_clst = C66727
## INCLUDE:  OTHERSP is null check
ds <- ds %>%
  assign_ct(
    raw_dat = ds_raw,
    raw_var = "IT.DSDECOD",
    tgt_var = "DSDECOD",
    ct_spec = study_ct,
    ct_clst = "C66727", 
    id_vars = oak_id_vars()
  ) %>% 
  #mutate(DSCAT = if_else(DSDECOD == "RANDOMIZED", "PROTOCOL MILESTONE", "DISPOSITION EVENT" ))
  hardcode_ct(
    raw_dat = condition_add(ds_raw, IT.DSDECOD == "Randomized"),
    raw_var = "IT.DSDECOD",
    tgt_var = "DSCAT",
    tgt_val = "PROTOCOL MILESTONE",
    ct_spec = study_ct,
    ct_clst = "C74558",
    id_vars = oak_id_vars()
  ) %>%
  hardcode_ct(
    raw_dat = condition_add(ds_raw, IT.DSDECOD != "Randomized"),
    raw_var = "IT.DSDECOD",
    tgt_var = "DSCAT",
    tgt_val = "DISPOSITION EVENT",
    ct_spec = study_ct,
    ct_clst = "C74558",
    id_vars = oak_id_vars()
  ) %>%
## CHECK FOR OTHERSP NOT NULL and update DSDECOD, DSTERM, DSCAT
  assign_no_ct(
              raw_dat = condition_add(ds_raw, !is.na(OTHERSP)),
              raw_var = "OTHERSP",
              tgt_var = "DSDECOD"
  ) %>%
  assign_no_ct(
    raw_dat = condition_add(ds_raw, !is.na(OTHERSP)),
    raw_var = "OTHERSP",
    tgt_var = "DSTERM"
    
  ) %>%
  hardcode_ct(
    raw_dat = condition_add(ds_raw, !is.na(OTHERSP)),
    raw_var = "OTHERSP",
    tgt_var = "DSCAT",
    tgt_val = "OTHER EVENT",
    ct_spec = study_ct,
    ct_clst = "C74558",
    id_vars = oak_id_vars()
  ) 
  

ds <- ds %>% 
  dplyr::mutate(
    STUDYID = ds_raw$STUDY,
    DOMAIN = "DS",
    USUBJID = paste0("01-", ds_raw$PATNUM) ) %>%
  # Derive RFPENDTC using oak_cal_ref_dates
  oak_cal_ref_dates(
    ds_in = .,
    der_var = "RFPENDTC",
    min_max = "max",
    ref_date_config_df = ref_date_conf_df,
    raw_source = list(
      ec_raw = ec_raw,
      ds_raw = ds_raw,
      dm_raw = dm_raw
    )
  ) %>%
  # Map DSDTC using assign_datetime
  assign_datetime(
    raw_dat = ds_raw,
    raw_var = "DSDTCOL",
    tgt_var = "DSDTC",
    raw_fmt = c("mm-dd-yyyy"),
    id_vars = oak_id_vars()
  ) %>%
  # Map DSSTDTC using assign_datetime, raw_var=IT.DSSTDAT
  assign_datetime(
    raw_dat = ds_raw,
    raw_var = "IT.DSSTDAT",
    tgt_var = "DSSTDTC",
    raw_fmt = c("mm-dd-yyyy"),
    id_vars = oak_id_vars()
  ) %>%
  derive_study_day(
    sdtm_in = .,
    dm_domain = dm,
    tgdt = "DSSTDTC",
    refdt = "RFSTDTC",
    study_day_var = "DSSTDY",
    merge_key = "USUBJID"
  ) %>%
  # Map VISIT from INSTANCE using assign_ct
  assign_ct(
    raw_dat = ds_raw,
    raw_var = "INSTANCE",
    tgt_var = "VISIT",
    ct_spec = study_ct,
    ct_clst = "VISIT",
    id_vars = oak_id_vars()
  ) %>%
  # Map VISITNUM from INSTANCE using assign_ct
  assign_ct(
    raw_dat = ds_raw,
    raw_var = "INSTANCE",
    tgt_var = "VISITNUM",
    ct_spec = study_ct,
    ct_clst = "VISITNUM",
    id_vars = oak_id_vars()
  ) %>%
  arrange(USUBJID, as.numeric(VISITNUM)) %>%
  derive_seq(
    tgt_var = "DSSEQ",
    rec_vars = c("USUBJID", "DSDTC", "VISITNUM") 
  ) %>%
  ## SELECT DS doamin variables
  dplyr::select("STUDYID", "DOMAIN", "USUBJID", "DSSEQ", "DSTERM", "DSDECOD", 
          "DSCAT", "VISITNUM", "VISIT", "DSDTC", "DSSTDTC", "DSSTDY")

save(ds,file = file.path( "created_ds.rda"))
