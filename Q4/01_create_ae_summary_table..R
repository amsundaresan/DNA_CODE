#------------------------------------------------------------
# Summary table
#------------------------------------------------------------


library(dplyr)
library(gtsummary)

adsl <- pharmaverseadam::adsl
adae <- pharmaverseadam::adae

# Pre-processing --------------------------------------------
adae <- adae |>
  filter(
    # Treatment emergent flag
    TRTEMFL == "Y" #,
    # serious adverse events
    #AESER == "Y"
  )

tbl <- adae |>
  tbl_hierarchical(
    variables = c(AESOC,AETERM),
    by = TRT01A,
    id = USUBJID,
    denominator = adsl,
    overall_row = TRUE,,
    label = "..ard_hierarchical_overall.." ~ "Treatment Emergent AEs"
  )

tbl

tbl |>
  as_gt() |>
  gt::gtsave("TEAE_summarytable.html")

