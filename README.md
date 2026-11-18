# One Question at a Time

Each week, one question about the current NBA season, answered with a Bayesian
workflow. Written in R and Quarto; models in Stan via cmdstanr and brms.

Site: <https://michaelpaullight.github.io/nba-one-question/>

## Layout

```
nba-one-question/
├── _quarto.yml              site config
├── index.qmd, about.qmd     home page (post listing) and about page
├── posts/
│   ├── _metadata.yml        defaults for every post (freeze, author)
│   ├── _template/           the workflow template new posts are copied from
│   └── YYYY-MM-DD-slug/     one folder per post, self-contained:
│       ├── index.qmd          the writing and analysis
│       ├── stan/              the post's Stan models
│       └── data/              dated data snapshots (+ JSON provenance)
├── _freeze/                 computed results of each post (committed)
├── R/                       shared helpers, sourced by every post
├── tests/testthat/          tests for R/
├── scripts/                 setup.R, new_post.R
├── DESCRIPTION              the project's package dependencies
└── renv.lock                exact package versions (created by setup.R)
```

## Principles

- **A post is a self-contained, reproducible unit.** Everything a post needs
  that isn't a shared helper lives in its folder.
- **Data is frozen per post.** The season changes nightly, so `snapshot()`
  saves the data a post used as `data/<name>_<as_of>.parquet` with a JSON
  sidecar (source code of the fetch, timestamp, row count, checksum). Later
  renders read the file and warn if it has changed.
- **Computation is frozen per post.** `freeze: true` means a post only runs when
  rendered explicitly. Rendering the site (and CI) reuses `_freeze/`, so old
  posts are never silently refit with new data or new package versions.
- **Simulate before you fit.** Every post follows the template: question →
  estimand → scientific model (DAG) → generative simulation → statistical
  model → prior predictive check → parameter recovery on simulated data →
  real data → computational diagnostics → posterior predictive check →
  answer → what could be wrong.
- **Package versions are pinned** with renv; the CmdStan version and git commit
  are printed in each post's reproducibility appendix.

## Setup on a new machine

Requires R (≥ 4.3), Quarto, and a C++ toolchain for Stan (Xcode command line
tools on macOS, Rtools on Windows).

```sh
git clone https://github.com/MichaelPaulLight/nba-one-question.git
cd nba-one-question
Rscript scripts/setup.R      # renv library + CmdStan; first run creates renv.lock
```

### One-time GitHub Pages setup

1. Create the `gh-pages` branch once from your machine: `quarto publish gh-pages`.
2. In the repo's Settings → Pages, set Source to "Deploy from a branch",
   branch `gh-pages`, folder `/ (root)`.

After that, every push to `main` republishes the site.

## Weekly workflow

```sh
git switch -c post/thunder-defense                       # one branch per post
Rscript scripts/new_post.R "Is the Thunder's defense as good as its record?"
# write and iterate; render just this post:
quarto render posts/2026-11-25-is-the-thunders-defense-as-good-as-its-record/index.qmd
quarto preview                                            # view the whole site
```

When it's ready: remove `draft: true`, render the post one final time, and
commit the post folder **and** its `_freeze/` folder. Merge to `main`; GitHub
Actions renders the site from the frozen results and publishes to `gh-pages`.

## Tests

```r
testthat::test_dir("tests/testthat")
```

## Adding a package

Add it to `DESCRIPTION`, then `renv::install("pkg")` and `renv::snapshot()`,
and commit `DESCRIPTION` and `renv.lock` together.
