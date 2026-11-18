# Computational diagnostics ----------------------------------------------------
#
# One table answering "can I trust this sampler run?" for both cmdstanr and
# brms fits. Thresholds follow the Stan team's current recommendations
# (Vehtari et al. 2021, "Rank-normalization, folding, and localization").

#' Summarise MCMC diagnostics for a fit
#'
#' @param fit A `CmdStanMCMC` (cmdstanr) or `brmsfit` object.
#' @param variables Optional character vector of variables to check R-hat and
#'   ESS for. Defaults to all variables.
#' @return A data frame with one row per check and an `ok` column.
check_fit <- function(fit, variables = NULL, rhat_max = 1.01, ess_min = 400) {
  if (inherits(fit, "CmdStanMCMC")) {
    sampler <- fit$diagnostic_summary(quiet = TRUE)
    n_div <- sum(sampler$num_divergent)
    n_treedepth <- sum(sampler$num_max_treedepth)
    ebfmi <- sampler$ebfmi
    draws <- fit$draws(variables)
  } else if (inherits(fit, "brmsfit")) {
    n_div <- rstan::get_num_divergent(fit$fit)
    n_treedepth <- rstan::get_num_max_treedepth(fit$fit)
    ebfmi <- rstan::get_bfmi(fit$fit)
    draws <- posterior::as_draws_array(fit, variable = variables)
  } else {
    stop("`fit` must be a CmdStanMCMC or brmsfit object.", call. = FALSE)
  }

  conv <- posterior::summarise_draws(draws, "rhat", "ess_bulk", "ess_tail")
  summarise_diagnostics(
    n_div = n_div,
    n_treedepth = n_treedepth,
    ebfmi = ebfmi,
    rhat = conv$rhat,
    ess_bulk = conv$ess_bulk,
    ess_tail = conv$ess_tail,
    rhat_max = rhat_max,
    ess_min = ess_min
  )
}

#' Turn raw diagnostic values into a pass/fail table (pure, so it is testable)
summarise_diagnostics <- function(n_div, n_treedepth, ebfmi, rhat, ess_bulk,
                                  ess_tail, rhat_max = 1.01, ess_min = 400) {
  worst <- c(
    divergences = n_div,
    max_treedepth_hits = n_treedepth,
    min_ebfmi = min(ebfmi),
    max_rhat = max(rhat, na.rm = TRUE),
    min_ess_bulk = min(ess_bulk, na.rm = TRUE),
    min_ess_tail = min(ess_tail, na.rm = TRUE)
  )
  data.frame(
    check = names(worst),
    value = unname(signif(worst, 4)),
    target = c("0", "0", "> 0.3", paste("<", rhat_max),
               paste(">", ess_min), paste(">", ess_min)),
    ok = c(
      worst[["divergences"]] == 0,
      worst[["max_treedepth_hits"]] == 0,
      worst[["min_ebfmi"]] > 0.3,
      worst[["max_rhat"]] < rhat_max,
      worst[["min_ess_bulk"]] > ess_min,
      worst[["min_ess_tail"]] > ess_min
    )
  )
}
