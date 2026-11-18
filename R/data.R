# Dated data snapshots ---------------------------------------------------------
#
# The season changes every night, so a post is only reproducible if the data it
# used is frozen. `snapshot()` fetches data once, saves it as a dated Parquet
# file next to the post, and writes a JSON sidecar recording where it came from
# and a checksum. Every later render reads the saved file instead of the network.

#' Load a dated snapshot, fetching and saving it the first time
#'
#' @param name Short snake_case name, e.g. "team_box".
#' @param as_of Data cutoff date. Passed to `fetch`, which should drop
#'   anything after it, so a snapshot taken late still means "as of this date".
#' @param fetch A function of one argument (`as_of`) that returns a data frame.
#' @param dir Folder to store snapshots in. Defaults to the post's `data/`
#'   folder (Quarto runs each post with its own folder as working directory).
#' @param refresh If TRUE, fetch again and overwrite the saved snapshot.
#' @return The data frame.
snapshot <- function(name, as_of, fetch, dir = "data", refresh = FALSE) {
  stopifnot(
    is.character(name), length(name) == 1, grepl("^[a-z0-9_]+$", name),
    is.function(fetch)
  )
  as_of <- as.Date(as_of)
  path <- snapshot_path(name, as_of, dir)
  meta_path <- sub("\\.parquet$", ".json", path)

  if (file.exists(path) && !refresh) {
    verify_snapshot(path, meta_path)
    return(nanoparquet::read_parquet(path))
  }

  df <- fetch(as_of)
  if (!is.data.frame(df)) stop("`fetch` must return a data frame.", call. = FALSE)

  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  nanoparquet::write_parquet(df, path)
  jsonlite::write_json(
    list(
      name = name,
      as_of = format(as_of),
      fetched_at_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      rows = nrow(df),
      columns = names(df),
      md5 = unname(tools::md5sum(path)),
      fetch = paste(deparse(fetch), collapse = "\n"),
      r_version = R.version.string
    ),
    meta_path, auto_unbox = TRUE, pretty = TRUE
  )
  df
}

snapshot_path <- function(name, as_of, dir = "data") {
  file.path(dir, paste0(name, "_", format(as.Date(as_of)), ".parquet"))
}

#' Warn if a snapshot no longer matches the checksum recorded when it was made
verify_snapshot <- function(path, meta_path) {
  if (!file.exists(meta_path)) {
    warning("No metadata found for snapshot ", path, call. = FALSE)
    return(invisible(FALSE))
  }
  meta <- jsonlite::read_json(meta_path)
  ok <- identical(unname(tools::md5sum(path)), meta$md5)
  if (!ok) {
    warning(
      "Snapshot ", path, " has changed since it was recorded on ",
      meta$fetched_at_utc, ". Results may not match the published post.",
      call. = FALSE
    )
  }
  invisible(ok)
}
