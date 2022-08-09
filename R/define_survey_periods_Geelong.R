#' .. content for \description{} (no empty lines) ..
#'
#' .. content for \details{} ..
#'
#' @title

#' @return
#' @author Nick Golding
#' @export
define_survey_periods_Geelong <- function() {

  tibble(
    summer_start_date = "2020-01-16",
    summer_end_date = "2020-04-28",
    winter_start_date = "2020-11-28",
    winter_end_date = "2020-12-19"
  ) %>%
    mutate(
      across(
        everything(),
        as.Date
      )
    )
  
}
