// Example model: partial pooling of team three-point shooting.
// Replace this with the model for your question.
//
// Set prior_only = 1 to ignore the likelihood and sample from the prior
// (used for the prior predictive check).
data {
  int<lower=1> N;                       // number of teams
  array[N] int<lower=0> attempts;       // three-point attempts
  array[N] int<lower=0> makes;          // three-point makes
  int<lower=0, upper=1> prior_only;
}
parameters {
  real mu;                              // league-average log-odds of a make
  real<lower=0> tau;                    // between-team sd (log-odds)
  vector[N] z;                          // non-centered team effects
}
transformed parameters {
  vector[N] theta = mu + tau * z;       // team log-odds of a make
}
model {
  mu ~ normal(-0.5, 0.3);               // league average roughly 25% to 52%
  tau ~ exponential(5);                 // teams differ by a few points, not 20
  z ~ std_normal();
  if (!prior_only) {
    makes ~ binomial_logit(attempts, theta);
  }
}
generated quantities {
  vector[N] p = inv_logit(theta);
  array[N] int makes_rep = binomial_rng(attempts, p);
}
