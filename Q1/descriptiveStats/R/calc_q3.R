#' Calculate the third quartile (Q3)
#'
#' Computes the 75th percentile while removing missing values (`NA`).
#' If any values are missing, a warning "NAs were removed" is issued.
#' If all values are missing, the function returns `NA_real_` with a warning.
#'
#' @param x A numeric vector.
#' @return A single numeric value: the third quartile of `x` excluding `NA`s,
#'   or `NA_real_` if all values are missing.
#'
#' @examples
#' calc_q3(c(1, 2, 3, 4))
#' calc_q3(c(1, 2, NA, 10))
#' calc_q3(c(NA, NA))
#'
#' @importFrom stats quantile
#' @export
calc_q3 <- function(x) { 

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

  quantile(x, probs = 0.75, na.rm = TRUE, names = FALSE)
}
