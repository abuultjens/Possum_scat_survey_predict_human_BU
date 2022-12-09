#' .. content for \description{} (no empty lines) ..
#'
#' .. content for \details{} ..
#'
#' @title

#' @return
#' @author Nick Golding
#' @export
load_cases <- function() {
  
  # load all case files
  cases_file <- "data/cases_MB_YEAR.xlsx"
  
  bind_rows(
    load_cases_file(cases_file)
  ) %>%
    mutate(
      #exposure_MB2011 = as.character(exposure_MB2011),
      MB2011 = as.character(MB2011),
      symptom_onset_date = as.Date(date),
      # incubation period (infection to onset) has a IQR (50% CI) of 101-171
      # days
      exposure_start_date = symptom_onset_date - 171,
      exposure_end_date = symptom_onset_date - 101,
      #      exposure_start_date = symptom_onset_date - 264,
      #      exposure_end_date = symptom_onset_date - 32,
    ) %>%
    # filter(
    #   type_of_contact == "Resident" | !is.na(exposure_MB2011),
    #   !is.na(symptom_onset_date) 
    # ) %>%
    # mutate(
    #   MB2011 = coalesce(exposure_MB2011, MB2011)
    # ) %>%
    select(
      StudyID,
      MB2011,
      symptom_onset_date,
      exposure_start_date,
      exposure_end_date,
      likely_exposure
    ) %>%
    arrange(
      symptom_onset_date
    )
  
}
