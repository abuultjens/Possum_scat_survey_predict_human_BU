#' .. content for \description{} (no empty lines) ..
#'
#' .. content for \details{} ..
#'
#' @title
#' @param case_count_previous_block
#' @return
#' @author Nick Golding
#' @export
# probability of observing any cases, given the expected number of cases,
# under a poisson sampling assumption
prob_any_cases <- function(expected_cases) {
  # equal to:
  #   1 - dpois(0, expected_cases)
  1 - exp(-expected_cases)
}

# log probability of observing any cases, given the expected number of cases,
# under a poisson sampling assumption
log_prob_any_cases <- function(expected_cases) {
  # equal to:
  #  log(1 - dpois(0, expected_cases))
  # and 
  #  log(1 - exp(-expected_cases))
  log1mexpm(expected_cases)
}

# numerically more stable calculation of log(1 - exp(-x))
log1mexpm <- function(x) {
  # Praise be to Martin Maechler:
  # https://cran.r-project.org/web/packages/Rmpfr/vignettes/log1mexp-note.pdf
  ifelse(x <= log(2), log(-expm1(-x)), log1p(-exp(-x)))
}

# probability of observing no cases, given the expected number of cases, under a
# poisson sampling assumption
prob_no_cases <- function(expected_cases) {
  # equal to:
  #  1 - prob_any_cases(expected_cases)
  #  dpois(0, expected_cases)
  exp(-expected_cases)
}

# log probability of observing no cases, given the expected number of cases, under a
# poisson sampling assumption
log_prob_no_cases <- function(expected_cases) {
  # equal to:
  #  log(prob_no_cases(expected_cases))
  #  log(1 - prob_any_case(expected_cases))
  #  log(1 - (1 - exp(-expected_cases)))
  #  log(exp(-expected_cases))
  -expected_cases
}