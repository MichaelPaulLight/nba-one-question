test_that("slugify makes folder-safe slugs", {
  expect_equal(slugify("Is the Thunder's defense real?"), "is-the-thunders-defense-real")
  expect_equal(slugify("  76ers / Knicks: who's better?  "), "76ers-knicks-whos-better")
  expect_lte(nchar(slugify(strrep("long title ", 20))), 50)
  expect_false(grepl("-$", slugify(strrep("ab ", 30))))
})
