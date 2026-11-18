test_that("snapshot fetches once, then reads from disk", {
  dir <- withr::local_tempdir()
  calls <- 0
  fetch <- function(as_of) {
    calls <<- calls + 1
    data.frame(game_date = as.Date(c("2026-11-01", "2026-11-20")), pts = c(110, 98)) |>
      subset(game_date <= as_of)
  }

  first <- snapshot("games", "2026-11-15", fetch, dir = dir)
  second <- snapshot("games", "2026-11-15", fetch, dir = dir)

  expect_equal(calls, 1)
  expect_equal(nrow(first), 1)                 # cutoff respected
  expect_equal(as.data.frame(second), as.data.frame(first))
  expect_true(file.exists(file.path(dir, "games_2026-11-15.parquet")))
  meta <- jsonlite::read_json(file.path(dir, "games_2026-11-15.json"))
  expect_equal(meta$as_of, "2026-11-15")
  expect_equal(meta$rows, 1)
})

test_that("snapshot warns when the saved file was altered", {
  dir <- withr::local_tempdir()
  fetch <- function(as_of) data.frame(x = 1:3)
  snapshot("toy", "2026-11-15", fetch, dir = dir)

  nanoparquet::write_parquet(data.frame(x = 4:6), snapshot_path("toy", "2026-11-15", dir))
  expect_warning(snapshot("toy", "2026-11-15", fetch, dir = dir), "has changed")
})

test_that("snapshot rejects bad names and non-data-frame results", {
  dir <- withr::local_tempdir()
  expect_error(snapshot("Bad Name", "2026-11-15", function(a) data.frame(), dir = dir))
  expect_error(snapshot("ok", "2026-11-15", function(a) 1:3, dir = dir), "data frame")
})
