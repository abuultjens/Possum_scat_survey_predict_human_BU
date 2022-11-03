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
model_likelihood_incidence <- function(cases, expected_cases) {
  llik <- dpois(x = cases,
                lambda = expected_cases,
                log = TRUE)
  sum(llik)
}
