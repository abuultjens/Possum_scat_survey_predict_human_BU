#' .. content for \description{} (no empty lines) ..
#'
#' .. content for \details{} ..
#'
#' @title
#' @param cases
#' @param expected_cases
#' @return
#' @author Nick Golding
#' @export
model_likelihood_presence <- function(cases, expected_cases) {
  any_cases <- cases > 0
  # numerically stable calculation of the log PMF of a bernoulli distribution,
  # with probability given by the probability of observing any cases under a
  # Poisson sampling distribution.
  # Equal to:
  #   llik <- dbinom(x = any_cases,
  #                  size = 1,
  #                  prob = prob_any_cases(expected_cases),
  #                  log = TRUE)
  log_prob_any <- log_prob_any_cases(expected_cases)
  log_prob_none <- log_prob_no_cases(expected_cases)
  llik <- ifelse(any_cases, log_prob_any, log_prob_none)
  sum(llik)
}



