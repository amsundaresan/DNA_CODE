#' Calculate the mode of a numeric vector
#'
#' Returns the most frequent value after removing missing values (`NA`).
#' If any values are missing, a warning "NAs were removed" is issued.
#' If all values are missing, the function returns `NA_real_` with a warning.
#' If there is a tie for most frequent value, the smallest value is returned.
#'
#' @param x A numeric vector.
#' @return A single numeric value: the mode of `x` excluding `NA`s,
#'   or `NA_real_` if all values are missing.
#'
#' @examples
#' calc_mode(c(1, 2, 2, 3))
#' calc_mode(c(1, 1, 2, 2))
#' calc_mode(c(NA, NA))
#'
#' @export
calc_mode <- function(x) {
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

  x <- x[!is.na(x)]

  tab <- table(x)
  mode_vals <- as.numeric(names(tab)[tab == max(tab)])

  # In case of ties, return the smallest value (deterministic behavior)
  min(mode_vals)
}
