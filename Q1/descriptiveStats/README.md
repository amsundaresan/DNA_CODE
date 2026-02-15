
# descriptiveStats

**descriptiveStats** is an R package providing **robust summary statistics functions** for numeric vectors.  
It handles missing values (`NA`), empty vectors, and single-value vectors gracefully.  
When the input contains any `NA`, functions issue a warning **"NAs were removed"** before computing on the non-missing values.

## Installation

You can install the development version of descriptiveStats like so:

```r
# Install devtools if not already installed
install.packages("devtools")

# Install from local path
devtools::install("~/path/to/descriptiveStats")

# Or install from GitHub
# devtools::install_github("amsundaresan/DNA_CODE/Q1/descriptiveStats")

#To install the rom GitHub run:

pak::pkg_install("amsundaresan/DNA_CODE/Q1/descriptiveStats", dependencies = TRUE)

```

## Testing

```r
devtools::test()

```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
## basic example code
library(descriptiveStats)
x <- c(1, 2, 2, 3, NA)

calc_mean(x)    # 2 (warning: NAs were removed)
calc_median(x)  # 2
calc_mode(x)    # 2
calc_q1(x)      # 1.5
calc_q3(x)      # 2.5
calc_iqr(x)     # 1

# Edge cases
calc_mean(numeric(0))        # NA with warning
calc_median(NA_real_)        # NA with warning
calc_mode(c(NA, NA))         # NA with warning
calc_iqr(c(5))               # 0
```




