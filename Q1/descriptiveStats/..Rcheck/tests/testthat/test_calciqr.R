test_that("calc_iqr works for a simple case", {
  # For c(1,2,3,4): Q1 = 1.75, Q3 = 3.25 → IQR = 1.5
  expect_equal(calc_iqr(c(1, 2, 3, 4)), 1.5)
})

test_that("calc_iqr ignores NA values", {
  # For c(1,2,10): R default quantile (type 7) gives Q1 = 1.5, Q3 = 6 → IQR = 4.5
  expect_equal(calc_iqr(c(1, 2, NA, 10)), 4.5)
})

test_that("calc_iqr returns NA when all values are NA", {
  expect_warning(
    expect_equal(calc_iqr(c(NA, NA)), NA_real_),
    "All values are NA"
  )
})

test_that("calc_iqr errors for non-numeric input", {
  expect_error(calc_iqr(c("a", "b")), "x must be numeric")
  expect_error(calc_iqr(list(1, 2, 3)), "x must be numeric")
})

test_that("calc_iqr works for length-1 vectors", {
  expect_equal(calc_iqr(5), 0)        # Q3 = Q1 = 5 → IQR = 0
  expect_warning(
    expect_equal(calc_iqr(NA_real_), NA_real_),
    "All values are NA"
  )
})

test_that("calc_iqr returns a double", {
  expect_type(calc_iqr(c(1, 2, 3, 4)), "double")
})

test_that("handles empty vector", {
  expect_warning(
    expect_equal(calc_iqr(numeric(0)), NA_real_),
    "Empty vector"
  )
})

test_that("handles all-NA vector", {
  expect_warning(
    expect_equal(calc_iqr(c(NA, NA)), NA_real_),
    "All values are NA"
  )
})

test_that("handles single value", {
  expect_equal(calc_iqr(5), 0)
  expect_warning(
    expect_equal(calc_iqr(NA_real_), NA_real_),
    "All values are NA"
  )
})
