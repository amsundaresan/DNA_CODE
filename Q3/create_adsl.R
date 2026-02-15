library(admiral)
library(dplyr, warn.conflicts = FALSE)
library(pharmaversesdtm)
library(lubridate)
library(stringr)

dm <- pharmaversesdtm::dm
ds <- pharmaversesdtm::ds
ex <- pharmaversesdtm::ex
ae <- pharmaversesdtm::ae
lb <- pharmaversesdtm::lb

dm <- convert_blanks_to_na(dm)
ds <- convert_blanks_to_na(ds)
ex <- convert_blanks_to_na(ex)
ae <- convert_blanks_to_na(ae)
lb <- convert_blanks_to_na(lb)

adsl <- dm %>%
  select(-DOMAIN)

# treatment variables
adsl <- dm %>%
  mutate(TRT01P = ARM, TRT01A = ACTARM)

# Impute start and end time of exposure to first and last respectively,
# Do not impute date
ex_ext <- ex %>%
  derive_vars_dtm(
    dtc = EXSTDTC,
    new_vars_prefix = "EXST"
  ) %>%
  derive_vars_dtm(
    dtc = EXENDTC,
    new_vars_prefix = "EXEN",
    time_imputation = "last"
  )

adsl <- adsl %>%
  derive_vars_merged(
    dataset_add = ex_ext,
    filter_add = (EXDOSE > 0 |
                    (EXDOSE == 0 &
                       str_detect(EXTRT, "PLACEBO"))) & !is.na(EXSTDTM),
    new_vars = exprs(TRTSDTM = EXSTDTM, TRTSTMF = EXSTTMF),
    order = exprs(EXSTDTM, EXSEQ),
    mode = "first",
    by_vars = exprs(STUDYID, USUBJID)
  ) %>%
  derive_vars_merged(
    dataset_add = ex_ext,
    filter_add = (EXDOSE > 0 |
                    (EXDOSE == 0 &
                       str_detect(EXTRT, "PLACEBO"))) & !is.na(EXENDTM),
    new_vars = exprs(TRTEDTM = EXENDTM, TRTETMF = EXENTMF),
    order = exprs(EXENDTM, EXSEQ),
    mode = "last",
    by_vars = exprs(STUDYID, USUBJID)
  )

## dtm to dt
adsl <- adsl %>%
  derive_vars_dtm_to_dt(source_vars = exprs(TRTSDTM, TRTEDTM))

#duration calc
adsl <- adsl %>%
  derive_var_trtdurd()

# Convert character date to numeric date without imputation
ds_ext <- derive_vars_dt(
  ds,
  dtc = DSSTDTC,
  new_vars_prefix = "DSST"
)

adsl <- adsl %>%
  derive_vars_merged(
    dataset_add = ds_ext,
    by_vars = exprs(STUDYID, USUBJID),
    new_vars = exprs(EOSDT = DSSTDT),
    filter_add = DSCAT == "DISPOSITION EVENT" & DSDECOD != "SCREEN FAILURE"
  )

format_eosstt <- function(x) {
  case_when(
    x %in% c("COMPLETED") ~ "COMPLETED",
    x %in% c("SCREEN FAILURE") ~ NA_character_,
    TRUE ~ "DISCONTINUED"
  )
}

adsl <- adsl %>%
  derive_vars_merged(
    dataset_add = ds,
    by_vars = exprs(STUDYID, USUBJID),
    filter_add = DSCAT == "DISPOSITION EVENT",
    new_vars = exprs(EOSSTT = format_eosstt(DSDECOD)),
    missing_values = exprs(EOSSTT = "ONGOING")
  )

adsl <- adsl %>%
  derive_vars_merged(
    dataset_add = ds,
    by_vars = exprs(USUBJID),
    new_vars = exprs(DCSREAS = DSDECOD, DCSREASP = DSTERM),
    filter_add = DSCAT == "DISPOSITION EVENT" &
      !(DSDECOD %in% c("SCREEN FAILURE", "COMPLETED", NA))
  )

## alternate derivations for DCREAS and DCREASP
  # adsl <- adsl %>%
  #   derive_vars_merged(
  #     dataset_add = ds,
  #     by_vars = exprs(USUBJID),
  #     new_vars = exprs(DCSREAS = DSDECOD),
  #     filter_add = DSCAT == "DISPOSITION EVENT" &
  #       DSDECOD %notin% c("SCREEN FAILURE", "COMPLETED", NA)
  #   ) %>%
  #   derive_vars_merged(
  #     dataset_add = ds,
  #     by_vars = exprs(USUBJID),
  #     new_vars = exprs(DCSREASP = DSTERM),
  #     filter_add = DSCAT == "DISPOSITION EVENT" & DSDECOD %in% "OTHER"
  #   )

## Randomization date
adsl <- adsl %>%
  derive_vars_merged(
    dataset_add = ds_ext,
    filter_add = DSDECOD == "RANDOMIZED",
    by_vars = exprs(STUDYID, USUBJID),
    new_vars = exprs(RANDDT = DSSTDT)
  )

# Derive birth date from BRTHDTC
adsl <- adsl %>%
  derive_vars_dt(
    new_vars_prefix = "BRTH",
    dtc = BRTHDTC
  )
## AAGE and AAGEU
adsl <- adsl %>%
  derive_vars_aage(
    start_date = BRTHDT,
    end_date = RANDDT
  )

## Death date
adsl <- adsl %>%
  derive_vars_dt(
    new_vars_prefix = "DTH",
    dtc = DTHDTC
  )

## cause of death
adsl <- adsl %>%
  derive_vars_extreme_event(
    by_vars = exprs(STUDYID, USUBJID),
    events = list(
      event(
        dataset_name = "ae",
        condition = AEOUT == "FATAL",
        set_values_to = exprs(DTHCAUS = AEDECOD),
      ),
      event(
        dataset_name = "ds",
        condition = DSDECOD == "DEATH" & grepl("DEATH DUE TO", DSTERM),
        set_values_to = exprs(DTHCAUS = DSTERM),
      )
    ),
    source_datasets = list(ae = ae, ds = ds),
    tmp_event_nr_var = event_nr,
    order = exprs(event_nr),
    mode = "first",
    new_vars = exprs(DTHCAUS)
  )
## death domain traceability
adsl <- adsl %>%
  select(-DTHCAUS) %>% # Remove it before deriving it again
  derive_vars_extreme_event(
    by_vars = exprs(STUDYID, USUBJID),
    events = list(
      event(
        dataset_name = "ae",
        condition = AEOUT == "FATAL",
        set_values_to = exprs(DTHCAUS = AEDECOD, DTHDOM = "AE", DTHSEQ = AESEQ),
      ),
      event(
        dataset_name = "ds",
        condition = DSDECOD == "DEATH" & grepl("DEATH DUE TO", DSTERM),
        set_values_to = exprs(DTHCAUS = DSTERM, DTHDOM = "DS", DTHSEQ = DSSEQ),
      )
    ),
    source_datasets = list(ae = ae, ds = ds),
    tmp_event_nr_var = event_nr,
    order = exprs(event_nr),
    mode = "first",
    new_vars = exprs(DTHCAUS, DTHDOM, DTHSEQ)
  )

#cause
adsl <- adsl %>%
  mutate(DTHCGR1 = case_when(
    is.na(DTHDOM) ~ NA_character_,
    DTHDOM == "AE" ~ "ADVERSE EVENT",
    str_detect(DTHCAUS, "(PROGRESSIVE DISEASE|DISEASE RELAPSE)") ~ "PROGRESSIVE DISEASE",
    TRUE ~ "OTHER"
  ))

#Relative Day of Death
adsl <- adsl %>%
  derive_vars_duration(
    new_var = DTHADY,
    start_date = TRTSDT,
    end_date = DTHDT
  )
#elapsed time from last dose
adsl <- adsl %>%
  derive_vars_duration(
    new_var = LDDTHELD,
    start_date = TRTEDT,
    end_date = DTHDT,
    add_one = FALSE
  )



## Derive groupings and populations
# Create lookup tables
agegr1_lookup <- exprs(
  ~condition,           ~AGEGR1,
  AAGE < 18,               "<18",
  between(AAGE, 18, 64), "18-64",
  AAGE > 64,               ">64",
  is.na(AAGE),         "Missing"
)

agegr9_lookup <- exprs(
  ~condition,           ~AGEGR9,
  AAGE < 18,               "<18",
  between(AAGE, 18, 50), "18-50",
  AAGE > 50,               ">50",
  is.na(AAGE),         "Missing"
)

agegr9_lookup_n <- exprs(
  ~condition,           ~AGEGR9N,
  AAGE < 18,               1,
  between(AAGE, 18, 50), 2,
  AAGE > 50,               3,
  is.na(AAGE),         NA
)

region1_lookup <- exprs(
  ~condition,                          ~REGION1,
  COUNTRY %in% c("CAN", "USA"), "North America",
  !is.na(COUNTRY),          "Rest of the World",
  is.na(COUNTRY),                     "Missing"
)


## use agegr9, >50
adsl <- adsl %>%
  derive_vars_cat(
    definition = agegr9_lookup
  ) %>%
  derive_vars_cat(
    definition = agegr9_lookup_n
  ) %>%
  derive_vars_cat(
    definition = agegr1_lookup
  ) %>%
  derive_vars_cat(
    definition = region1_lookup
  ) 

## Alternatively 
# format_agegr1 <- function(var_input) {
#   case_when(
#     var_input < 18 ~ "<18",
#     between(var_input, 18, 64) ~ "18-64",
#     var_input > 64 ~ ">64",
#     TRUE ~ "Missing"
#   )
# }
# format_region1 <- function(var_input) {
#   case_when(
#     var_input %in% c("CAN", "USA") ~ "North America",
#     !is.na(var_input) ~ "Rest of the World",
#     TRUE ~ "Missing"
#   )
# }
# 
# adsl %>%
#   mutate(
#     AGEGR1 = format_agegr1(AAGE),
#     REGION1 = format_region1(COUNTRY)
#   )

## ITTFL: Set to "Y" if [DM.ARM] not equal to missing Else set to "N"
adsl <- adsl %>%
  derive_var_merged_exist_flag(
    dataset_add = dm,
    by_vars = exprs(STUDYID, USUBJID),
    new_var = ITTFL,
    false_value = "N",
    missing_value = "N",
    condition = !is.na(AGE)
  )

#ABNSBPFL 
#"Y" if patient has an observation where [VS.VSTESTCD] = "SYSBP"
#and [VS.VSSTRESU] is "mmHg" and [VS.VSSTRESN] is greater than or equal to 140 or
#less than 100. Else set to "N"
adsl <- adsl %>%
  derive_var_merged_exist_flag(
    dataset_add = vs,
    by_vars = exprs(STUDYID, USUBJID),
    new_var = ABNSBPFL,
    false_value = "N",
    missing_value = "N",
    condition = (VSTESTCD == "SYSBP" & VSSTRESU == "mmHg" & (VSSTRESN >= 140 | VSSTRESN < 100  ) )
  )

# last know alive with traceability
adsl <- adsl %>%
  derive_vars_extreme_event(
    by_vars = exprs(STUDYID, USUBJID),
    events = list(
      event( # last complete date of vital assessment with a valid test result ([VS.VSSTRESN] and
       # [VS.VSSTRESC] not both missing) and datepart of [VS.VSDTC] not missing.
        dataset_name = "vs",
        order = exprs(VSDTC, VSSEQ),
        condition = !is.na(VSDTC) & !is.na(VSSTRESN) & !is.na(VSSTRESC),
        set_values_to = exprs(
          LSTALVDT = convert_dtc_to_dt(VSDTC, highest_imputation = "M"),
         # seq = VSSEQ,
          LALVSEQ = VSSEQ,
          LALVDOM = "VS",
          LALVVAR = "VSSTDTC"
        ),
      ),
      event( #last complete onset date of AEs (datepart of Start Date/Time of Adverse Event
        #[AE.AESTDTC]).
        dataset_name = "ae",
        order = exprs(AESTDTC, AESEQ),
        condition = !is.na(AESTDTC),
        set_values_to = exprs(
          LSTALVDT = convert_dtc_to_dt(AESTDTC, highest_imputation = "M"),
        #  seq = AESEQ,
          LALVSEQ = AESEQ,
          LALVDOM = "AE",
          LALVVAR = "AESTDTC"
        ),
      ),
      event( #last complete disposition date (datepart of Start Date/Time of Disposition Event
        #[DS.DSSTDTC]).
        dataset_name = "ds",
        order = exprs(DSSTDTC, DSSEQ),
        condition = !is.na(DSSTDTC),
        set_values_to = exprs(
          LSTALVDT = convert_dtc_to_dt(DSSTDTC, highest_imputation = "M"),
        #  seq = DSSEQ,
          LALVSEQ = DSSEQ,
          LALVDOM = "DS",
          LALVVAR = "DSSTDTC"
        ),
      ),
      event( #last date of treatment administration where patient received a valid dose (datepart of
        #Datetime of Last Exposure to Treatment [ADSL.TRTEDTM]).
        dataset_name = "adsl",
        condition = !is.na(TRTEDT),
        set_values_to = exprs(LSTALVDT = TRTEDT, seq = 0, LALVSEQ = NA_integer_, LALVDOM = "ADSL", LALVVAR = "TRTEDTM"),
      )
    ),
    source_datasets = list(vs = vs, ae = ae, ds = ds, adsl = adsl),
    tmp_event_nr_var = event_nr,
    order = exprs(LSTALVDT, LALVSEQ, event_nr),
    mode = "last", # Set to max 
    new_vars = exprs(LSTALVDT, LALVSEQ, LALVDOM, LALVVAR)
  )

## CARPOPFL: Set to "Y" if patient has an observation where uppercase of [AE.AESOC] =
# "CARDIAC DISORDERS". Else set to missing.
adsl <- adsl %>%
  derive_var_merged_exist_flag(
    dataset_add = ae,
    by_vars = exprs(STUDYID, USUBJID),
    new_var = CARPOPFL,
    false_value = "N",
    missing_value = "N",
    condition = AESOC == "CARDIAC DISORDERS"
  )


#Save file
save(adsl,file = file.path( "created_adsl.rda"))

