#' .. content for \description{} (no empty lines) ..
#'
#' .. content for \details{} ..
#'
#' @title
#' @param meshblock_incidence
#' @param rt_scat_positivity
#' @return
#' @author Nick Golding
#' @export
train_model <- function(meshblock_incidence,
                        rt_scat_positivity,
                        objective_type = c("incidence", "presence")) {
  
  # whether to fit ML solution against incidence likelihood, or presence
  # likelihood
  objective_type <- match.arg(objective_type)
  
  # split incidence and scat positivity into summer and winter surveys
  meshblock_incidence_summer <- meshblock_incidence %>%
    filter(
      period == "summer"
    )
  
  rt_scat_positivity_summer <- rt_scat_positivity %>%
    filter(
      period == "summer"
    )
  
  meshblock_incidence_winter <- meshblock_incidence %>%
    filter(
      period == "winter"
    )
  
  rt_scat_positivity_winter <- rt_scat_positivity %>%
    filter(
      period == "winter"
    )
  
  # pre-compute model objects, for faster inference
  model_objects <- list(
    # precompute distance matrices d_ij between meshblock locations and possum
    # scat sampling locations in each survey, in km
    distance = list(
      summer = get_distance(meshblock_incidence_summer, rt_scat_positivity_summer),
      winter = get_distance(meshblock_incidence_winter, rt_scat_positivity_winter)
    ),
    # scat positivity for each survey
    mu_positivity = list(
      summer = rt_scat_positivity_summer$mu_positive,
      winter = rt_scat_positivity_winter$mu_positive
    ),
    meshblock_incidence = list(
      summer = meshblock_incidence_summer,
      winter = meshblock_incidence_winter
    )
  )
  
  # find the maximum likelihood solution, with restarts
  n_restarts <- 5
  initials_raw <- replicate(n_restarts,
                            rnorm(2),
                            simplify = FALSE)
  
  # fit for each set of inital values
  fits <- lapply(initials_raw,
                 FUN = optim,
                 fn = model_objective,
                 model_objects = model_objects,
                 objective_type = objective_type,
                 hessian = TRUE)
  
  # get the negative log-likelihoods of each restart, to find the optimum
  nlls <- vapply(fits, `[[`, "value", FUN.VALUE = numeric(1))
  best_fit <- fits[[which.min(nlls)]]
  
  # return the best-fitting model (including the hessian from which to compute SDs on parameters)
  list(
    # model fit info
    fit = best_fit,  
    # parameter estimate summary
    parameters = summarise_model_parameters(best_fit),
    # model objects used for fitting
    model_objects = model_objects,
    # predictions to training data, for validation
    fitted = predict_incidence_seasons(best_fit$par, model_objects)
  )

  
}
