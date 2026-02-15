#' Calculate the interquartile range (IQR)
#'
#' Computes Q3 - Q1 while removing missing values (`NA`).
#' If any values are missing, a warning "NAs were removed" is issued.
#' If all values are missing, the function returns `NA_real_` with a warning.
#'
#' @param x A numeric vector.
#' @return A single numeric value: the interquartile range of `x`
#'   or `NA_real_` if all values are missing.
#'
#' @examples
#' calc_iqr(c(1, 2, 3, 4))
#' calc_iqr(c(1, 2, NA, 10))
#' calc_iqr(c(NA, NA))
#'
#' @importFrom stats quantile
#' @export
calc_iqr <- function(x) {
  if (length(x) == 0) {
    warning("Empty vector")
    return(NA_real_)
  }

  if (all(is.na(x))) {
    warning("All values are NA")
    return(NA_real_)
  }

  if (!is.numeric(x)) {
    stop("x must be numeric")
  }

  if (any(is.na(x))) {
    warning("NAs were removed")
  }

  q3 <- quantile(x, probs = 0.75, na.rm = TRUE, names = FALSE)
  q1 <- quantile(x, probs = 0.25, na.rm = TRUE, names = FALSE)

  q3 - q1
}
