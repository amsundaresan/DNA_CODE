test_that("calc_mean works for normal numeric input", {
  expect_equal(calc_mean(c(1, 2, 3, 4)), 2.5)
  expect_equal(calc_mean(c(10, 20, 30)), 20)
})

test_that("calc_mean removes NA values", {
  expect_equal(calc_mean(c(1, 2, NA, 4)), 2.33333333333333)
})

test_that("calc_mean returns NA when all values are NA", {
  expect_warning(
    expect_equal(calc_mean(c(NA, NA)), NA_real_),
    "All values are NA"
  )
})

test_that("calc_mean errors for non-numeric input", {
  expect_error(calc_mean(c("a", "b", "c")), "x must be numeric")
  expect_error(calc_mean(list(1, 2, 3)), "x must be numeric")
})

test_that("calc_mean works for length-1 vectors", {
  expect_equal(calc_mean(5), 5)
  expect_warning(
    expect_equal(calc_mean(NA_real_), NA_real_),
    "All values are NA"
  )
})

test_that("handles empty vector", {
  expect_warning(
    expect_equal(calc_mean(numeric(0)), NA_real_),
    "Empty vector"
  )
})

test_that("handles all-NA vector", {
  expect_warning(
    expect_equal(calc_mean(c(NA, NA)), NA_real_),
    "All values are NA"
  )
})

test_that("handles single value", {
  expect_equal(calc_mean(5), 5)
  expect_warning(
    expect_equal(calc_mean(NA_real_), NA_real_),
    "All values are NA"
  )
})
