test_that("summarise_diagnostics passes a healthy run", {
  out <- summarise_diagnostics(
    n_div = 0, n_treedepth = 0, ebfmi = c(0.9, 1.1),
    rhat = c(1.001, 1.004), ess_bulk = c(1500, 2100), ess_tail = c(1200, 1800)
  )
  expect_true(all(out$ok))
  expect_equal(nrow(out), 6)
})

test_that("summarise_diagnostics flags each kind of problem", {
  out <- summarise_diagnostics(
    n_div = 3, n_treedepth = 1, ebfmi = c(0.2, 0.9),
    rhat = c(1.05, NA), ess_bulk = c(150, 2000), ess_tail = c(90, 900)
  )
  expect_false(any(out$ok))
})
