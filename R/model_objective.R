#' .. content for \description{} (no empty lines) ..
#'
#' .. content for \details{} ..
#'
#' @title
#' @param params_raw
#' @return
#' @author Nick Golding
#' @export
# return the negative log-likelihood of the model, for optimisation
model_objective <- function(params_raw, model_objects, objective_type) {
  
  # predict incidence and cases
  predictions <- predict_incidence_seasons(params_raw, model_objects)
  
  # get the correct likelihood (whether evaluating against presenceor incidence)
  model_likelihood <- switch(objective_type,
                             incidence = model_likelihood_incidence,
                             presence = model_likelihood_presence)
  
  llik_summer <- model_likelihood(
    model_objects$meshblock_incidence$summer$cases,
    predictions$fitted_cases$summer
  )
  
  llik_winter <- model_likelihood(
    model_objects$meshblock_incidence$winter$cases,
    predictions$fitted_cases$winter
  )
  
  # compute and return the negative log-likelihood for both datasets combined
  nll <- -(llik_summer + llik_winter)
  
  nll
}
