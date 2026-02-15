test_that("calc_median works for odd-length vectors", {
  expect_equal(calc_median(c(1, 2, 3)), 2)
})

test_that("calc_median works for even-length vectors", {
  expect_equal(calc_median(c(1, 2, 3, 4)), 2.5)
})

test_that("calc_median removes NA values", {
  expect_equal(calc_median(c(1, 2, NA, 100)), 2)
})

test_that("calc_median returns NA when all values are NA", {
  expect_warning(
    expect_equal(calc_median(c(NA, NA)), NA_real_),
    "All values are NA"
  )
})

test_that("calc_median errors for non-numeric input", {
  expect_error(calc_median(c("a", "b")), "x must be numeric")
  expect_error(calc_median(list(1, 2, 3)), "x must be numeric")
})

test_that("calc_median works for length-1 vectors", {
  expect_equal(calc_median(5), 5)
  expect_warning(
    expect_equal(calc_median(NA_real_), NA_real_),
    "All values are NA"
  )
})

test_that("calc_median returns a double", {
  expect_type(calc_median(c(1, 2, 3)), "double")
})

test_that("handles empty vector", {
  expect_warning(
    expect_equal(calc_median(numeric(0)), NA_real_),
    "Empty vector"
  )
})

test_that("handles all-NA vector", {
  expect_warning(
    expect_equal(calc_median(c(NA, NA)), NA_real_),
    "All values are NA"
  )
})

test_that("handles single value", {
  expect_equal(calc_median(5), 5)
  expect_warning(
    expect_equal(calc_median(NA_real_), NA_real_),
    "All values are NA"
  )
})
