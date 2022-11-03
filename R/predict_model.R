#' .. content for \description{} (no empty lines) ..
#'
#' .. content for \details{} ..
#'
#' @title
#' @param fitted_model
#' @param meshblocks
#' @param rt_scat_positivity
#' @return
#' @author Nick Golding
#' @export
predict_model <- function(
  fitted_model,
  meshblocks,
  rt_scat_positivity
) {
  
  params <- transform_params(fitted_model$fit$par)
  distance <- get_distance(meshblocks, rt_scat_positivity)
  
  incidence_prediction <- project_incidence(
    params = params,
    distance = distance,
    positivity = rt_scat_positivity$mu_positive
  )
  
  meshblocks %>%
    mutate(
      incidence_pred = incidence_prediction[, 1]
    )
  
}

