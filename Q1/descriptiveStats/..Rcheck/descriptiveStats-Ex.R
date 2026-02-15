pkgname <- "descriptiveStats"
source(file.path(R.home("share"), "R", "examples-header.R"))
options(warn = 1)
library('descriptiveStats')

base::assign(".oldSearch", base::search(), pos = 'CheckExEnv')
base::assign(".old_wd", base::getwd(), pos = 'CheckExEnv')
cleanEx()
nameEx("calc_iqr")
### * calc_iqr

flush(stderr()); flush(stdout())

### Name: calc_iqr
### Title: Calculate the interquartile range (IQR)
### Aliases: calc_iqr

### ** Examples

calc_iqr(c(1, 2, 3, 4))
calc_iqr(c(1, 2, NA, 10))
calc_iqr(c(NA, NA))




cleanEx()
nameEx("calc_mean")
### * calc_mean

flush(stderr()); flush(stdout())

### Name: calc_mean
### Title: Calculate the mean of a numeric vector
### Aliases: calc_mean

### ** Examples

calc_mean(c(1, 2, 3, 4))
calc_mean(c(1, 2, NA, 4))
calc_mean(c(NA, NA))




cleanEx()
nameEx("calc_median")
### * calc_median

flush(stderr()); flush(stdout())

### Name: calc_median
### Title: Calculate the median of a numeric vector
### Aliases: calc_median

### ** Examples

calc_median(c(1, 2, 3, 4))
calc_median(c(1, 2, NA, 100))
calc_median(c(NA, NA))




cleanEx()
nameEx("calc_mode")
### * calc_mode

flush(stderr()); flush(stdout())

### Name: calc_mode
### Title: Calculate the mode of a numeric vector
### Aliases: calc_mode

### ** Examples

calc_mode(c(1, 2, 2, 3))
calc_mode(c(1, 1, 2, 2))
calc_mode(c(NA, NA))




cleanEx()
nameEx("calc_q1")
### * calc_q1

flush(stderr()); flush(stdout())

### Name: calc_q1
### Title: Calculate the first quartile (Q1)
### Aliases: calc_q1

### ** Examples

calc_q1(c(1, 2, 3, 4))
calc_q1(c(1, 2, NA, 10))
calc_q1(c(NA, NA))




cleanEx()
nameEx("calc_q3")
### * calc_q3

flush(stderr()); flush(stdout())

### Name: calc_q3
### Title: Calculate the third quartile (Q3)
### Aliases: calc_q3

### ** Examples

calc_q3(c(1, 2, 3, 4))
calc_q3(c(1, 2, NA, 10))
calc_q3(c(NA, NA))




### * <FOOTER>
###
cleanEx()
options(digits = 7L)
base::cat("Time elapsed: ", proc.time() - base::get("ptime", pos = 'CheckExEnv'),"\n")
grDevices::dev.off()
###
### Local variables: ***
### mode: outline-minor ***
### outline-regexp: "\\(> \\)?### [*]+" ***
### End: ***
quit('no')
