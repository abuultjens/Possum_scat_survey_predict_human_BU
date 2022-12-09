#' .. content for \description{} (no empty lines) ..
#'
#' .. content for \details{} ..
#'
#' @title
#' @param beta
#' @param sigma
#' @param meshblocks
#' @param rt_scat_positivity
#' @param cutoff_distance
#' @return
#' @author Nick Golding
#' @export
project_incidence <- function(params, distance, positivity) {
  
  # compute normalised weights; weighted positivity for a target location is an
  # average of positivity measures at all scat positivity sites, weighted
  # according to their distance from the target site. normalisation is the key
  # to ensuring this is an average and doesn't depend on sampling effort.
  weights_raw <- exp(-0.5 * (distance / params$sigma) ^ 2)
  weights <- sweep(weights_raw, 1, rowSums(weights_raw), FUN = "/")
  weighted_positivity <- weights %*% positivity
  
  incidence <- params$beta * weighted_positivity
  
  incidence
  
}
