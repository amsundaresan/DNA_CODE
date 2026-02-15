library(dplyr)
library(gtsummary)
library(lubridate)

# Load data
adae <- pharmaverseadam::adae
ds <- pharmaversesdtm::ds

#------------------------------------------------------------
# Remove screen fail patients
#------------------------------------------------------------
screen_fail_ids <- ds |>
  filter(DSDECOD == "SCREEN FAILURE") |>
  distinct(USUBJID) |>
  pull(USUBJID) 

# Filter out the screen fails
adae <- adae |>
  filter(!USUBJID %in% screen_fail_ids)

#------------------------------------------------------------
#  Filter Treatment-Emergent AEs
#------------------------------------------------------------
adae_te <- adae |>
  filter(TRTEMFL == "Y")

#------------------------------------------------------------
#  Select Columns of Interest
#------------------------------------------------------------
ae_listing <- adae_te |>
  arrange(USUBJID, AESTDTC) |>
  select(
    USUBJID,      # Subject ID
    ARM,          # Treatment
    AETERM,       # AE Term
    AESEV,        # Severity
    AEREL,        # Relationship to drug
    AESTDTC,      # Start Date
    AEENDTC       # End Date
  ) |>
  group_by(USUBJID) |>
  mutate( ## List USUBJID and ARM only the first time
    ARM = if_else(row_number() == 1, ARM, ""),
    USUBJID = if_else(row_number() == 1, USUBJID, "")
  ) |>
  ungroup() |>
  rename(
    `Unique Subject Identifier` = USUBJID,
    `Description of Actual Arm` = ARM,
    `Reported Term for the Adverse Event` = AETERM,
    `Severity/Intensity` = AESEV,
    `Causality` = AEREL,
    `Start Date/Time of Adverse Event` = AESTDTC,
    `End Date/Time of Adverse Event` = AEENDTC
  )



gt_tbl <- ae_listing |>
  gt() |>
  
  cols_align(
    align = "left",
    columns = everything()
  ) |>
  
  # clean-up table look
  tab_options(
    table.border.top.style = "none",
    table.border.bottom.style = "none",
    column_labels.border.top.style = "solid",
    column_labels.border.bottom.style = "solid",
    data_row.padding = px(2),
    table.font.size = px(12)
  ) |>
  
  # Add custom title block table
  tab_header(
    title = html(
      "<div style='text-align:left; font-weight:bold;'>
         Listing of Treatment-Emergent Adverse Events by Subject
       </div>"
    ),
    subtitle = html(
      "<div style='text-align:left;'>
         Excluding Screen Failure Patients
       </div>"
    )
  ) |>
  
  tab_options(
    heading.align = "left"
  )

# Save
gtsave(gt_tbl, "TEAE_listings.html")

