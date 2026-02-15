#------------------------------------------------------------
# Visualizations
#------------------------------------------------------------

#------------------------------------------------------------
# Plot1: AE severity distribution by treatment (bar chart)
#------------------------------------------------------------

library(dplyr)
library(ggplot2)

# Load data
adae <- pharmaverseadam::adae

# Optional: restrict to treatment-emergent AEs
adae_te <- adae |>
  filter(TRTEMFL == "Y")

# Summarize counts
plot_data <- adae_te |>
  filter(AESEV %in% c("MILD", "MODERATE", "SEVERE")) |>
  count(ARM, AESEV)

# Ensure consistent ordering
plot_data <- plot_data |>
  mutate(
    AESEV = factor(AESEV, levels = c("MILD", "MODERATE", "SEVERE"))
  )

# Create stacked bar plot
p <- ggplot(plot_data, aes(x = ARM, y = n, fill = AESEV)) +
  geom_bar(stat = "identity") +
  labs(
    title = "Adverse Event Severity by Treatment Arm",
    x = "Treatment Arm",
    y = "Number of Adverse Events",
    fill = "Severity"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5)
  )

# Save as PNG
ggsave(
  filename = "TEAE_Severity_by_arm.png",
  plot = p,
  width = 8,
  height = 6,
  dpi = 300
)

#------------------------------------------------------------
# Plot2: Top 10 most frequent AEs (with 95% CI for incidence rates).
#------------------------------------------------------------

library(dplyr)
library(ggplot2)
library(scales)
library(binom)

#------------------------------------------------------------
# 1. Load Data
#------------------------------------------------------------
adsl <- pharmaverseadam::adsl
adae <- pharmaverseadam::adae

#------------------------------------------------------------
# 2. Define Safety Population (Denominator)
#------------------------------------------------------------
safety_pop <- adsl |> 
  filter(SAFFL == "Y")

N <- n_distinct(safety_pop$USUBJID)

#------------------------------------------------------------
# 3. Filter Treatment-Emergent AEs
#------------------------------------------------------------
adae_te <- adae |>
  filter(TRTEMFL == "Y")

#------------------------------------------------------------
# 4. Count Unique Subjects per AETERM
#------------------------------------------------------------
ae_counts <- adae_te |>
  distinct(USUBJID, AETERM) |>
  count(AETERM, name = "n_subjects") |>
  arrange(desc(n_subjects)) |>
  slice_head(n = 10) # top 10

#------------------------------------------------------------
# 5. Compute Incidence and Clopper-Pearson Exact 95% CI
#------------------------------------------------------------
ae_counts <- ae_counts |>
  rowwise() |>
  mutate(
    proportion = n_subjects / N,
    ci = list(binom.confint(n_subjects, N, method = "exact")),
    lower = ci$lower,
    upper = ci$upper
  ) |>
  ungroup()

#------------------------------------------------------------
# 6. Create Plot
#------------------------------------------------------------
p <- ggplot(ae_counts,
            aes(x = reorder(AETERM, proportion),
                y = proportion)) +
  geom_col(fill = "steelblue") +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.2) +
  coord_flip() +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    title = "Top 10 Most Frequent Treatment-Emergent Adverse Events",
    subtitle = paste0(
      "Incidence Rate with Clopper–Pearson Exact 95% CI (N = ", N, ")"
    ),
    x = "Adverse Event (AETERM)",
    y = "Incidence Rate (%)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    plot.title.position = "plot"
  )

# Display
p

#------------------------------------------------------------
# 7. Save to PNG
#------------------------------------------------------------
ggsave(
  filename = "Top10_ae_incidence_exactCI.png",
  plot = p,
  width = 9,
  height = 7,
  dpi = 300
)

