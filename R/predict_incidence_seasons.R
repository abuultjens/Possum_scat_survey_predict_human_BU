#' .. content for \description{} (no empty lines) ..
#'
#' .. content for \details{} ..
#'
#' @title
#' @param params_raw
#' @param model_objects
#' @return
#' @author Nick Golding
#' @export
predict_incidence_seasons <- function(params_raw, model_objects) {
  
  params <- transform_params(params_raw)
  
  incidence_summer <- project_incidence(
    params,
    distance = model_objects$distance$summer,
    positivity = model_objects$mu_positivity$summer
  )
  
  incidence_winter <- project_incidence(
    params,
    distance = model_objects$distance$winter,
    positivity = model_objects$mu_positivity$winter
  )
  
  expected_cases_summer <- incidence_summer * model_objects$meshblock_incidence$summer$pop
  expected_cases_winter <- incidence_winter * model_objects$meshblock_incidence$winter$pop
  
  list(
    fitted_incidence = list(
      summer = incidence_summer,
      winter = incidence_winter
    ),
    fitted_cases = list(
      summer = expected_cases_summer,
      winter = expected_cases_winter
    )
  )
}
