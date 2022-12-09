#' .. content for \description{} (no empty lines) ..
#'
#' .. content for \details{} ..
#'
#' @title
#' @param params_raw
#' @return
#' @author Nick Golding
#' @export
transform_params <- function(params_raw) {
  list(
    sigma = exp(params_raw[1]),
    beta = exp(params_raw[2])
  )
}