# One-time setup on a new machine. Run from the project root:
#   Rscript scripts/setup.R
#
# 1. Creates a project library with renv and installs the packages listed in
#    DESCRIPTION (renv "explicit" mode: DESCRIPTION is the list of
#    dependencies, renv.lock records their exact versions).
# 2. Installs CmdStan, the Stan compiler that cmdstanr and brms use.
#
# After this, `renv::restore()` reproduces the same library anywhere.
# When you add a package: add it to DESCRIPTION, `renv::install("pkg")`,
# then `renv::snapshot()` and commit renv.lock.

repos <- c(
  CRAN = "https://packagemanager.posit.co/cran/latest",
  stan = "https://stan-dev.r-universe.dev"  # cmdstanr is not on CRAN
)
options(repos = repos)

if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")

if (file.exists("renv.lock")) {
  # Existing project on a new machine: reproduce the recorded library.
  renv::restore(prompt = FALSE)
} else {
  # First time: create the project library and record it.
  renv::init(bare = TRUE, settings = list(snapshot.type = "explicit"),
             repos = repos, restart = FALSE)
  renv::install(prompt = FALSE)
  renv::snapshot(prompt = FALSE)
}

# CmdStan lives outside the project (in ~/.cmdstan); its version is recorded
# in each post's reproducibility appendix.
cmdstanr::check_cmdstan_toolchain(fix = TRUE)
if (is.na(cmdstanr::cmdstan_version(error_on_NA = FALSE))) {
  cmdstanr::install_cmdstan(cores = max(1, parallel::detectCores() - 1))
}

message("Setup complete. Commit renv.lock, .Rprofile and renv/ (renv ignores its own library).")
