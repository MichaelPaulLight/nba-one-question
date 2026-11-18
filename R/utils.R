# Small shared helpers ---------------------------------------------------------

#' Turn a post title into a folder-safe slug
slugify <- function(x, max_chars = 50) {
  x <- tolower(x)
  x <- gsub("'", "", x)                 # "Thunder's" -> "thunders"
  x <- gsub("[^a-z0-9]+", "-", x)
  x <- gsub("^-+|-+$", "", x)
  x <- substr(x, 1, max_chars)
  sub("-+$", "", x)
}

#' A plain ggplot2 theme used for every figure on the blog
theme_blog <- function(base_size = 12) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      plot.title.position = "plot",
      plot.caption = ggplot2::element_text(colour = "grey40", hjust = 0),
      legend.position = "bottom"
    )
}

#' What a reader needs to reproduce a post, for the appendix
repro_info <- function(data_dir = "data") {
  git <- function(...) {
    out <- tryCatch(
      suppressWarnings(system2("git", c(...), stdout = TRUE, stderr = FALSE)),
      error = function(e) NA_character_
    )
    if (length(out) == 0) NA_character_ else out[1]
  }
  snapshots <- list.files(data_dir, pattern = "\\.parquet$", full.names = TRUE)
  cmdstan <- tryCatch(
    as.character(cmdstanr::cmdstan_version(error_on_NA = FALSE)),
    error = function(e) NA_character_
  )
  list(
    rendered_at_utc = format(Sys.time(), "%Y-%m-%d %H:%M UTC", tz = "UTC"),
    git_commit = git("rev-parse", "--short", "HEAD"),
    uncommitted_changes = !is.na(git("status", "--porcelain")),
    r_version = R.version.string,
    cmdstan_version = cmdstan,
    data_snapshots = if (length(snapshots)) {
      stats::setNames(unname(tools::md5sum(snapshots)), basename(snapshots))
    } else {
      "none"
    }
  )
}
