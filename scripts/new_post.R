#!/usr/bin/env Rscript
# Start a new post from the template.
#
# Usage (from the project root):
#   Rscript scripts/new_post.R "Is the Thunder's defense as good as its record?"
#   Rscript scripts/new_post.R "Title" 2026-11-25     # set the date / data cutoff
#
# Creates posts/<date>-<slug>/ with index.qmd, stan/ and data/.

source("R/utils.R")

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) stop('Usage: Rscript scripts/new_post.R "Post title" [YYYY-MM-DD]')

title <- args[[1]]
date <- if (length(args) >= 2) as.Date(args[[2]]) else Sys.Date()
dir <- file.path("posts", paste0(format(date), "-", slugify(title)))

if (dir.exists(dir)) stop("Post folder already exists: ", dir)
dir.create(file.path(dir, "stan"), recursive = TRUE)
dir.create(file.path(dir, "data"))

template <- readLines("posts/_template/index.qmd")
template <- gsub("{{title}}", gsub('"', '\\\\"', title), template, fixed = TRUE)
template <- gsub("{{date}}", format(date), template, fixed = TRUE)
template <- gsub("{{seed}}", format(date, "%Y%m%d"), template, fixed = TRUE)
writeLines(template, file.path(dir, "index.qmd"))

invisible(file.copy("posts/_template/stan/model.stan", file.path(dir, "stan", "model.stan")))

message("Created ", dir, "\nRender it with: quarto render ", file.path(dir, "index.qmd"))
