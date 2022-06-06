
# Build model on MP data and then predict on G data

# load packages
library(raster)
library(tidyverse)
library(readxl)
library(sf)
library(greta)
library(rgdal)
library(flexclust)
library(multidplyr)
library(dplyr)
library(caret)

# load R scripts
source("R/load.R")

# import pos args
args <- commandArgs(trailingOnly = TRUE)

##########################################################

# predict BU incidence at meshblock level as a distace-weighted function of MU
# positivity in possum scat and possum abundance.

# possum abundance multiplied by scat prevalence should be proportional to the
# number of infected possums at a location, which is proportional to the
# force-of-infection (FOI) from possums to mosquitos at that location.

# assuming a uniform abundance of mosquitoes within the study area, the
# prevalence of MU amongst moquitoes should be a monotone increasing function of
# this FOI, and likely close to proportional, given the very large numbers of
# mosquitoes and low observed prevalence in mosquitoes (little saturation).

# the prevalence in mosquitoes should be proportional to the FOI from mosquitoes
# to humans, and therefore the incidence among humans (low incidence and no
# immunity, so unlikely to saturate)

# the movement ranges of possums and humans about their home locations, and the
# dispersal of mosquitoes, mean that the locations of higher possum abundance
# and scat positivity will not correspond exactly with the hotspots of human
# cases. Instead, the incidence likelihood should be a distance-weighted average
# of the FOI to mosquitoes.

# model the FOI to mosquitoes as a function of possum abundance and scat
# positivity

# We have a continuous modelled surface of expected possum abundance, and point
# locations where possum scats have been screened for MU. We want to be able to
# predict BU incidence from the MU scat positivity, so we can use this a
# predictive tool in the future, for targetting interventions

# So we want a simple model to predict BU incidence on map, and therefore
# compute the expected number of cases at meshblock level.

# step 1: load data

# load in possum abundance map
possum_density <- load_possum_density() # has Geelong data
possum_density_Geelong <- load_possum_density_Geelong() # has Geelong data


# load in all scat locations and MU positivity
scat_positivity <- load_scat_positivity(toString(args[3]))
scat_positivity_Geelong <- load_scat_positivity_Geelong()

# subset to RT scats, and prepare for modelling, extracting possum densities
rt_scat_positivity <- prep_rt_scat_positivity(scat_positivity, possum_density) # selects by season
rt_scat_positivity_Geelong <- prep_rt_scat_positivity_Geelong(scat_positivity_Geelong, possum_density)


# load in meshblock coordinates, cropping to peninsula
meshblocks <- load_meshblocks()
meshblocks_Geelong <- load_meshblocks_Geelong()

# load in residential BU cases and use 2016 populations and specify upsample rate
cases <- load_cases(as.integer(args[1])) # has all data including Geelong epi data

# assign survey periods and seasons
cases_survey_periods <- assign_survey_periods(cases)
cases_survey_periods_Geelong <- assign_survey_periods_Geelong(cases)

cases_seasons <- assign_seasons(cases)
cases_seasons_Geelong <- assign_seasons_Geelong(cases)

# plot these a la Koen, to check they make sense
#plot_cases_by_period(cases_survey_periods)
#plot_cases_by_period(cases_survey_periods_Geelong)

# and plot by season
#plot_cases_by_period(cases_seasons)

# compute incidence by meshblock, grouped by scat survey period
meshblock_incidence_survey_periods <- prep_meshblock_incidence(cases_survey_periods,meshblocks)
meshblock_incidence_survey_periods_Geelong <- prep_meshblock_incidence(cases_survey_periods_Geelong,meshblocks_Geelong)

# meshblock_incidence_survey_periods: 1840 x 7
meshblock_incidence_seasons <- prep_meshblock_incidence(cases_seasons,meshblocks)
meshblock_incidence_seasons_Geelong <- prep_meshblock_incidence(cases_seasons_Geelong,meshblocks_Geelong)

# plot meshblock incidence by season
#plot_meshblock_incidence_by_period(meshblock_incidence_seasons)
#plot_meshblock_incidence_by_period(meshblock_incidence_seasons_Geelong)

# 1. train the model on two separate periods - DONE

# 2. do spatial block CV on these (3 blocks) to validate model
#    - pull out the prediction code into a function - DONE
#    - wrap up the fitting and prediction code in functions - DONE
#    - define spatial blocks - DONE
#    - loop through blocks, fitting and predicting

# 3. compare hold-out predictions against prediction based on previous
# incidence by meshblock (null model)

n_cv_blocks <- 3

# define a spatial block pattern for cross-validation
meshblock_incidence_survey_periods_blocked <- define_blocks(meshblock_incidence_survey_periods,n_blocks = n_cv_blocks)
meshblock_incidence_survey_periods_blocked_Geelong <- define_blocks(meshblock_incidence_survey_periods_Geelong,n_blocks = n_cv_blocks)

# plot these blocks
#plot_blocked_incidence(meshblock_incidence_survey_periods_blocked)
#plot_blocked_incidence(meshblock_incidence_survey_periods_blocked_Geelong)

# split into training and testing sets
training <- split_data(meshblock_incidence_survey_periods_blocked,which = "train")

testing <- split_data(meshblock_incidence_survey_periods_blocked,which = "test")
testing_Geelong <- split_data(meshblock_incidence_survey_periods_blocked_Geelong,which = "test")

# fit model to entire dataset in the Mornington Peninsula and predict to all of Geelong
fitted_model_overall <- train_model(
  meshblock_incidence = meshblock_incidence_survey_periods,
  rt_scat_positivity = rt_scat_positivity,
  cutoff_distance = as.numeric(args[2])
)

saveRDS(fitted_model_overall, toString(args[4]))

prediction_Geelong <- predict_model(
  fitted_model_overall,
  meshblocks = meshblock_incidence_survey_periods_Geelong,
  rt_scat_positivity = rt_scat_positivity_Geelong
)

saveRDS(prediction_Geelong, toString(args[5]))

predictions_all <- prediction_Geelong

blocking <- predictions_all %>%st_drop_geometry() %>%select(meshblock) %>%distinct()
previous_incidence = meshblock_incidence_seasons_Geelong %>%st_drop_geometry() %>%dplyr::filter(period == "2019",meshblock %in% predictions_all$meshblock) %>%dplyr::left_join(blocking,by = "meshblock") %>%dplyr::rename(incidence_meshblock_2019 = incidence) %>%dplyr::mutate(incidence_block_2019 = sum(cases) / sum(pop)) %>%dplyr::ungroup() %>%dplyr::select(meshblock,incidence_meshblock_2019,incidence_block_2019)
predictions_to_evaluate <- predictions_all %>%left_join(previous_incidence,by = "meshblock") %>%left_join(survey_period_incidence_multipliers(),by = "period") %>%mutate(annualincidence = incidence / multiplier,pred_annualincidence_model = incidence_pred_mean / multiplier,pred_annualincidence_meshblock2019 = incidence_meshblock_2019,pred_annualincidence_cvblock2019 = incidence_block_2019,) %>%mutate(pred_cases_model = incidence_pred_mean * pop,pred_cases_meshblock2019 = incidence_meshblock_2019 * multiplier * pop,pred_cases_cvblock2019 = incidence_block_2019 * multiplier * pop,) %>%mutate(any = as.numeric(cases > 0),pred_any_model = prob_any_cases(pred_cases_model),pred_any_meshblock2019 = prob_any_cases(pred_cases_meshblock2019),pred_any_cvblock2019 = prob_any_cases(pred_cases_cvblock2019),) %>%pivot_longer(cols = starts_with("pred_"),names_to = c(".value", "prediction"),names_pattern = "(.*)_(.*)") %>%select(period,meshblock,cases,annualincidence,any,method = prediction,starts_with("pred")) %>%mutate(method = factor(method,levels = c("model", "meshblock2019", "cvblock2019")))

# write AUC to csv
tmp <- predictions_to_evaluate %>%dplyr::group_by(method) %>%dplyr::summarise(cor_annualincidence = cor(annualincidence, pred_annualincidence),dev_cases = poisson_deviance(cases, pred_cases),auc_any = Metrics::auc(any, pred_any)) %>%dplyr::arrange(method)
write.table(tmp$auc_any[1] , sep=",", file = toString(args[7]), row.names = FALSE, col.names = FALSE)

# write predictions_to_evaluate_DF to file
predictions_to_evaluate_DF <- as.data.frame(predictions_to_evaluate %>% dplyr::filter(method == "model")) %>% dplyr::filter(period == "summer")
write.table(predictions_to_evaluate_DF , sep=",", file = toString(args[6]), row.names = FALSE, col.names = TRUE, quote = FALSE)

# write matrix and stats to csv
cm <- confusionMatrix(data= as.factor(round(predictions_to_evaluate_DF$pred_any)), reference = as.factor(predictions_to_evaluate_DF$any))
stats <- cm$byClass
write.table(stats , sep=",", file = toString(args[8]), row.names = TRUE, col.names = FALSE, quote = FALSE)
matrix <- cm$table
write.table(matrix , sep=",", file = toString(args[9]), row.names = FALSE, col.names = FALSE)

# write any and pred_any to csv
write.table(predictions_to_evaluate_DF$any , sep=",", file = toString(args[10]), row.names = FALSE, col.names = FALSE)
write.table(predictions_to_evaluate_DF$pred_any, sep=",",file=toString(args[11]), row.names = FALSE, col.names = FALSE)

data <- predictions_to_evaluate

PROP=0.05
# count total number of cases (G)
tmp <- data %>% dplyr::filter(period == "summer") %>% dplyr::filter(method == "model")
total_count <- sum(tmp$any == "1") 
# count total number of cases in fraction (G)
tmp <- data %>% dplyr::filter(period == "summer") %>% dplyr::filter(method == "model") %>% dplyr::slice_max(pred_any, prop = PROP) %>% dplyr::filter(any == "1")
count <- sum(tmp$any == "1") 
PROP_MP_G_0.05 <- count/total_count

PROP=0.1
# count total number of cases (G)
tmp <- data %>% dplyr::filter(period == "summer") %>% dplyr::filter(method == "model")
total_count <- sum(tmp$any == "1") 
# count total number of cases in fraction (G)
tmp <- data %>% dplyr::filter(period == "summer") %>% dplyr::filter(method == "model") %>% dplyr::slice_max(pred_any, prop = PROP) %>% dplyr::filter(any == "1")
count <- sum(tmp$any == "1") 
PROP_MP_G_0.1 <- count/total_count

PROP=0.2
# count total number of cases (G)
tmp <- data %>% dplyr::filter(period == "summer") %>% dplyr::filter(method == "model")
total_count <- sum(tmp$any == "1") 
# count total number of cases in fraction (G)
tmp <- data %>% dplyr::filter(period == "summer") %>% dplyr::filter(method == "model") %>% dplyr::slice_max(pred_any, prop = PROP) %>% dplyr::filter(any == "1")
count <- sum(tmp$any == "1") 
PROP_MP_G_0.2 <- count/total_count

PROP=0.5
# count total number of cases (G)
tmp <- data %>% dplyr::filter(period == "summer") %>% dplyr::filter(method == "model")
total_count <- sum(tmp$any == "1") 
# count total number of cases in fraction (G)
tmp <- data %>% dplyr::filter(period == "summer") %>% dplyr::filter(method == "model") %>% dplyr::slice_max(pred_any, prop = PROP) %>% dplyr::filter(any == "1")
count <- sum(tmp$any == "1") 
PROP_MP_G_0.5 <- count/total_count

param <- toString(args[12])

MODEL <- c(param)
PROP_MP_G_0.05 <- c(PROP_MP_G_0.05)
PROP_MP_G_0.1 <- c(PROP_MP_G_0.1)
PROP_MP_G_0.2 <- c(PROP_MP_G_0.2)
PROP_MP_G_0.5 <- c(PROP_MP_G_0.5)

df <- data.frame(MODEL, PROP_MP_G_0.05, PROP_MP_G_0.1, PROP_MP_G_0.2, PROP_MP_G_0.5)
write.table(df , sep=",", file = toString(args[13]), row.names = FALSE, quote = FALSE)
