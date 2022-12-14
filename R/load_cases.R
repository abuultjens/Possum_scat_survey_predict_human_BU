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
#  cases_file_to_2019 <- "data/BU NHMRC NickGolding SpatialEpi data NO PHESSID_upd 26 Nov 2019.xlsx"
#  cases_file_2019_2020 <- "data/BU NHMRC NickGolding SpatialEpi data with NO PHESSID_2019 and 2020.xlsx"
#  cases_file_2021 <- "data/BU NHMRC NickGolding SpatialEpi data NO PHESSID_Jan to 9 Nov 2021.xlsx"

  cases_file_to_2019 <- "data/US-27 BU NHMRC NickGolding SpatialEpi data NO PHESSID_upd 26 Nov 2019.xlsx"
  cases_file_2019_2020 <- "data/US-27 BU NHMRC NickGolding SpatialEpi data with NO PHESSID_2019 and 2020.xlsx"
  cases_file_2021 <- "data/US-27 BU NHMRC NickGolding SpatialEpi data NO PHESSID_Jan to 9 Nov 2021.xlsx"
    
#  cases_file_to_2019 <- "upsampling/US-30_BU_NHMRC_NickGolding_SpatialEpi_data_NO_PHESSID_upd_26_Nov_2019.xlsx"
#  cases_file_2019_2020 <- "upsampling/US-30_BU_NHMRC_NickGolding_SpatialEpi_data_with_NO_PHESSID_2019_and_2020.xlsx"
#  cases_file_2021 <- "upsampling/US-30_BU_NHMRC_NickGolding_SpatialEpi_data_NO_PHESSID_Jan_to_9_Nov_2021.xlsx"
  
  bind_rows(
#    read_csv(cases_file_to_2019),
#    read_csv(cases_file_2019_2020),
#    read_csv(cases_file_2021)    
    load_cases_file(cases_file_to_2019),
    load_cases_file(cases_file_2019_2020),
    load_cases_file(cases_file_2021)
  ) %>%
    mutate(
      exposure_MB2011 = as.character(exposure_MB2011),
      symptom_onset_date = as.Date(date),
      # incubation period (infection to onset) has a IQR (50% CI) of 101-171
      # days
#      exposure_start_date = symptom_onset_date - 171,
#      exposure_end_date = symptom_onset_date - 101,
      exposure_start_date = symptom_onset_date - 264,
      exposure_end_date = symptom_onset_date - 32,      
    ) %>%
    filter(
      type_of_contact == "Resident" | !is.na(exposure_MB2011),
      !is.na(symptom_onset_date)
    ) %>%
    mutate(
      MB2011 = coalesce(exposure_MB2011, MB2011) 
    ) %>%
    select(
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
