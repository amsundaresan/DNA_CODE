test_that("calc_q3 works for a simple case", {
  # For this vector, Q3 = 3.25 using R's default method
  expect_equal(calc_q3(c(1, 2, 3, 4)), 3.25)
})

test_that("calc_q3 ignores NA values", {
  # For c(1, 2, 10): R default quantile (type 7) gives Q3 = 6
  expect_equal(calc_q3(c(1, 2, NA, 10)), 6)
})

test_that("calc_q3 returns NA when all values are NA", {
  expect_warning(
    expect_equal(calc_q3(c(NA, NA)), NA_real_),
    "All values are NA"
  )
})

test_that("calc_q3 errors for non-numeric input", {
  expect_error(calc_q3(c("a", "b")), "x must be numeric")
  expect_error(calc_q3(list(1, 2, 3)), "x must be numeric")
})

test_that("calc_q3 works for length-1 vectors", {
  expect_equal(calc_q3(5), 5)
  expect_warning(
    expect_equal(calc_q3(NA_real_), NA_real_),
    "All values are NA"
  )
})

test_that("calc_q3 returns a double", {
  expect_type(calc_q3(c(1, 2, 3, 4)), "double")
})

test_that("handles empty vector", {
  expect_warning(
    expect_equal(calc_q3(numeric(0)), NA_real_),
    "Empty vector"
  )
})

test_that("handles all-NA vector", {
  expect_warning(
    expect_equal(calc_q3(c(NA, NA)), NA_real_),
    "All values are NA"
  )
})

test_that("handles single value", {
  expect_equal(calc_q3(5), 5)
  expect_warning(
    expect_equal(calc_q3(NA_real_), NA_real_),
    "All values are NA"
  )
})
