#' .. content for \description{} (no empty lines) ..
#'
#' .. content for \details{} ..
#'
#' @title
#' @param fit
#' @return
#' @author Nick Golding
#' @export
summarise_model_parameters <- function(fit) {

  # get parameter estimates and standard deviations on log-scale:
  log_params <- fit$par
  log_sds <- sqrt(diag(solve(fit$hessian)))
  
  # compute parameter estimates on correct scale
  params <- transform_params(log_params)
  
  # compute CIs on parameter estimates
  lower <- qlnorm(0.025, log_params, log_sds)
  upper <- qlnorm(0.975, log_params, log_sds)
  names(lower) <- names(upper) <- names(params)
  
  # return all
  cbind(
    estimate = c(params),
    lower_95 = lower,
    upper_95 = upper
  )
  
}
