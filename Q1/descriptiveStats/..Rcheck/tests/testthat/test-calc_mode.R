test_that("calc_mode works for a clear mode", {
  expect_equal(calc_mode(c(1, 2, 2, 3)), 2)
})

test_that("calc_mode handles ties deterministically", {
  # Both 1 and 2 appear twice → should return the smaller one
  expect_equal(calc_mode(c(1, 1, 2, 2)), 1)
})

test_that("calc_mode ignores NAs", {
  expect_equal(calc_mode(c(1, 2, NA, 2)), 2)
})

test_that("calc_mode returns NA when all values are NA", {
  expect_warning(
    expect_equal(calc_mode(c(NA, NA)), NA_real_),
    "All values are NA"
  )
})

test_that("calc_mode errors for non-numeric input", {
  expect_error(calc_mode(c("a", "b")), "x must be numeric")
  expect_error(calc_mode(list(1, 2, 3)), "x must be numeric")
})

test_that("calc_mode works for length-1 vectors", {
  expect_equal(calc_mode(5), 5)
  expect_warning(
    expect_equal(calc_mode(NA_real_), NA_real_),
    "All values are NA"
  )
})

test_that("calc_mode returns a double", {
  expect_type(calc_mode(c(1, 2, 2)), "double")
})

test_that("handles empty vector", {
  expect_warning(
    expect_equal(calc_mode(numeric(0)), NA_real_),
    "Empty vector"
  )
})

test_that("handles all-NA vector", {
  expect_warning(
    expect_equal(calc_mode(c(NA, NA)), NA_real_),
    "All values are NA"
  )
})

test_that("handles single value", {
  expect_equal(calc_mode(5), 5)
  expect_warning(
    expect_equal(calc_mode(NA_real_), NA_real_),
    "All values are NA"
  )
})
