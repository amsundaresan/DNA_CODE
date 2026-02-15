# descriptiveStats 0.0.0.9000

## New features

* Initial release with descriptive statistics functions:
  * `calc_mean()` - arithmetic mean (NA removed)
  * `calc_median()` - median (NA removed)
  * `calc_mode()` - most frequent value, ties broken by smallest value
  * `calc_iqr()` - interquartile range (Q3 - Q1, R default quantile type 7)
  * `calc_q1()` - first quartile (25th percentile)
  * `calc_q3()` - third quartile (75th percentile)
* All functions handle empty vectors and all-NA input with a warning and return `NA_real_`.
* Non-numeric input raises an error with message "x must be numeric".

## Bug fixes / behavior

* Empty and all-NA checks run before the numeric check so that logical all-NA vectors (e.g. `c(NA, NA)`) are handled correctly instead of triggering "x must be numeric".
