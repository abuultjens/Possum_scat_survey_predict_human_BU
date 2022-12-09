
# Build model on MP data and then predict on G data

# load packages
library(sf)
library(raster) 
library(tidyverse) 
library(readxl) 
library(flexclust) 

# load R scripts
source("R/load.R")

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
scat_positivity <- load_scat_positivity()
scat_positivity_Geelong <- load_scat_positivity_Geelong()

# subset to RT scats, and prepare for modelling, extracting possum densities
rt_scat_positivity <- prep_rt_scat_positivity(
  scat_positivity,
  possum_density
) # selects by season

rt_scat_positivity_Geelong <- prep_rt_scat_positivity_Geelong(
  scat_positivity_Geelong,
  possum_density
)

# load in meshblock coordinates, cropping to peninsula
meshblocks <- load_meshblocks()
meshblocks_Geelong <- load_meshblocks_Geelong()

# load in residential BU cases and use 2016 populations and specify upsample rate
cases <- load_cases()

# assign survey periods and seasons
cases_survey_periods <- assign_survey_periods(cases)
cases_survey_periods_Geelong <- assign_survey_periods_Geelong(cases)

cases_seasons <- assign_seasons(cases)
cases_seasons_Geelong <- assign_seasons_Geelong(cases)

# plot these a la Koen, to check they make sense
# plot_cases_by_period(cases_survey_periods)
# plot_cases_by_period(cases_survey_periods_Geelong)

# and plot by season
# plot_cases_by_period(cases_seasons)

# compute incidence by meshblock, grouped by scat survey period
meshblock_incidence_survey_periods <- prep_meshblock_incidence(
  cases_survey_periods,
  meshblocks
)
meshblock_incidence_survey_periods_Geelong <- prep_meshblock_incidence(
  cases_survey_periods_Geelong,
  meshblocks_Geelong
)

# meshblock_incidence_survey_periods: 1840 x 7
meshblock_incidence_seasons <- prep_meshblock_incidence(
  cases_seasons,
  meshblocks
)
meshblock_incidence_seasons_Geelong <- prep_meshblock_incidence(
  cases_seasons_Geelong,
  meshblocks_Geelong
)

# plot meshblock incidence by season
# plot_meshblock_incidence_by_period(meshblock_incidence_seasons)
# plot_meshblock_incidence_by_period(meshblock_incidence_seasons_Geelong)

# fit model to entire dataset in the Mornington Peninsula and predict to all of Geelong
fitted_model_overall <- train_model(
  meshblock_incidence = meshblock_incidence_survey_periods,
  rt_scat_positivity = rt_scat_positivity,
  objective_type = "presence"
)

saveRDS(fitted_model_overall, "MP-G_US-1_PRESENCE_101-171_AB-DATA_MP-MP_MODEL.RDS")

prediction_Geelong <- predict_model(
  fitted_model_overall,
  meshblocks = meshblock_incidence_survey_periods_Geelong,
  rt_scat_positivity = rt_scat_positivity_Geelong
  ) %>%
  dplyr::filter(
    period == "summer"
  )

saveRDS(prediction_Geelong, "MP-G_US-1_PRESENCE_101-171_AB-DATA_MP-G_MODEL.RDS")

predictions_all <- prediction_Geelong

write.table(prediction_Geelong,
            sep = ",",
            file = "prediction_Geelong_MP-G.csv",
            row.names = FALSE,
            quote = FALSE)

# replace case numbers greater than 1 with 1
prediction_Geelong$cases[prediction_Geelong$cases >= 1] <- 1


##############################################################
# evaluate meshblock2018 previous year incidence model
##############################################################

blocking <- predictions_all %>%
  st_drop_geometry() %>%
  select(meshblock) %>%
  distinct()
previous_incidence <- meshblock_incidence_seasons_Geelong %>%
  st_drop_geometry() %>%
  dplyr::filter(
    period == "2019",
    meshblock %in% predictions_all$meshblock
  ) %>%
  dplyr::left_join(
    blocking,
    by = "meshblock"
  ) %>%
  dplyr::rename(
    incidence_meshblock_2019 = incidence
  ) %>%
  dplyr::mutate(
    incidence_block_2019 = sum(cases) / sum(pop)
  ) %>%
  dplyr::ungroup() %>%
  dplyr::select(
    meshblock,
    incidence_meshblock_2019,
    incidence_block_2019
  )

meshblock2019_predictions_to_evaluate <- predictions_all %>%
  left_join(
    previous_incidence,
    by = "meshblock"
  ) %>%
  left_join(
    survey_period_incidence_multipliers(),
    by = "period"
  ) %>%
  mutate(
    annualincidence = incidence / multiplier,
    pred_annualincidence_model = incidence_pred / multiplier,
    pred_annualincidence_meshblock2019 = incidence_meshblock_2019,
    pred_annualincidence_cvblock2019 = incidence_block_2019
  ) %>%
  mutate(
    pred_cases_model = incidence_pred * pop,
    pred_cases_meshblock2019 = incidence_meshblock_2019 * multiplier * pop,
    pred_cases_cvblock2019 = incidence_block_2019 * multiplier * pop
  ) %>%
  mutate(
    any = as.numeric(cases > 0),
    pred_any_model = prob_any_cases(pred_cases_model),
    pred_any_meshblock2019 = prob_any_cases(pred_cases_meshblock2019),
    pred_any_cvblock2019 = prob_any_cases(pred_cases_cvblock2019)
  ) %>%
  pivot_longer(
    cols = starts_with("pred_"),
    names_to = c(".value", "prediction"),
    names_pattern = "(.*)_(.*)"
  ) %>%
  select(
    period,
    meshblock,
    cases,
    annualincidence,
    any,
    method = prediction,
    starts_with("pred")
  ) %>%
  mutate(
    method = factor(
      method,
      levels = c(
        "model",
        "meshblock2019",
        "cvblock2019"
      )
    )
  )

# convert meshblock2019_predictions_to_evaluate to dataframe
meshblock2019_predictions_to_evaluate_DF <- meshblock2019_predictions_to_evaluate %>%
  dplyr::filter(
    period == "summer"
  ) %>%
  dplyr::filter(
    method == "meshblock2019"
  ) %>%
  as.data.frame()

# write meshblock2019_predictions_to_evaluate to file
write.table(meshblock2019_predictions_to_evaluate_DF,
            sep = ",",
            file = "meshblock2019_predictions_to_evaluate.csv",
            row.names = FALSE, 
            col.names = TRUE, 
            quote = FALSE)

###### calculate AUC for previous year incidence
data <- meshblock2019_predictions_to_evaluate_DF
tmp_AUC <- data %>%
  dplyr::summarise(
    auc_any = Metrics::auc(cases, pred_any)
  ) 

# write AUC for previous year incidence to file
write.table(tmp_AUC$auc_any[1],
            sep = ",",
            file = "2019_MP-G_previous_year_incidence_AUC.csv",
            row.names = FALSE,
            col.names = FALSE)



##############################################################
# evaluate scat-model
##############################################################

# calculate AUC for model
data <- prediction_Geelong
tmp_AUC <- data %>%
  as.data.frame() %>%
  dplyr::summarise(
    auc_any = Metrics::auc(cases, incidence_pred)
  ) 

# write model AUC to file
write.table(tmp_AUC$auc_any[1],
            sep = ",",
            file = "MP-G_US-1_PRESENCE_101-171_AB-DATA_AUC.csv",
            row.names = FALSE,
            col.names = FALSE)

# write matrix and stats to csv
#cm <- confusionMatrix(
#  data = as.factor(round(prediction_Geelong$incidence_pred)),
#  reference = as.factor(prediction_Geelong$cases)
#)

#stats <- cm$byClass

#write.table(stats,
#            sep = ",",
#            file = "MP-G_US-1_PRESENCE_101-171_AB-DATA_stats.csv",
#            row.names = TRUE,
#            col.names = FALSE,
#            quote = FALSE)

#matrix <- cm$table
#write.table(matrix,
#            sep = ",",
#            file = "MP-G_US-1_PRESENCE_101-171_AB-DATA_matrix.csv",
#            row.names = FALSE,
#            col.names = FALSE)

# write any and pred_any to csv
write.table(prediction_Geelong$cases,
            sep = ",",
            file = "MP-G_US-1_PRESENCE_101-171_AB-DATA_any.csv",
            row.names = FALSE,
            col.names = FALSE)

write.table(prediction_Geelong$incidence_pred,
            sep = ",",
            file = "MP-G_US-1_PRESENCE_101-171_AB-DATA_pred_any.csv",
            row.names = FALSE,
            col.names = FALSE)


##############################################################
# calculate scat-model ranking
##############################################################

##############################################################

# TEST scat-model MP-MP

data <- data.frame(predictions_all)

tmp_df <- data %>%
  arrange(desc(meshblock)
  )

all <- tmp_df[, c("meshblock")]
all <- data.frame(all)
INDEX <- data.frame(all)

x <- 1:10

for (val in x) {
  
  data$rand <- sample(100, size = nrow(data), replace = TRUE, )
  
  tmp <- data %>%
    arrange(desc(rand)
    ) %>%
    arrange(desc(incidence_pred)
    )
  
  tmp$seq <- 1:nrow(tmp)
  
  tmp <- tmp %>%
    arrange(desc(meshblock)
    )
  
  subset <- tmp[, c("seq")]
  
  all <- cbind(all, subset)
}

all <- subset(all, select = -c(all))

means <- data.frame(matrix(ncol = 1, nrow = nrow(all)))
means$means <- data.frame(rowMeans(all, na.rm = FALSE, dims = 1))

all_means <- cbind(INDEX$all, means$means)

top20 <- all_means %>% 
  distinct(INDEX$all, .keep_all = TRUE
  ) %>% 
  arrange(rowMeans.all..na.rm...FALSE..dims...1.
  ) %>% 
  dplyr::slice_head(n = (0.20 * nrow(data)))

write.table(top20$`INDEX$all`,
            sep = ",",
            file = toString(sprintf("TOP-20_MP-G_scat-model.csv")),
            row.names = FALSE,
            col.names = FALSE,
            quote = FALSE)

##############################################################

data <- prediction_Geelong %>%
  dplyr::filter(
    period == "summer"
  )

x <- 1:100

# make df
df_loop <- data.frame(matrix(ncol = 4, nrow = 0))
colnames(df_loop) <- c("0.05", "0.10", "0.20", "0.50")

for (val in x) {
  
  data$rand <- sample(100, size = nrow(data), replace = TRUE, )
  
  PROP <- 0.05
  # count total number of cases (G)
  tmp <- data
  total_count <- sum(tmp$cases == "1")
  
  # count total number of cases in fraction (G)
  tmp <- data %>%
    arrange(desc(rand)
    ) %>%
    arrange(desc(incidence_pred)
    ) %>%
    dplyr::slice_head(
      n = (PROP * nrow(data))
    ) %>%
    dplyr::filter(
      cases == "1"
    )
  count <- sum(tmp$cases == "1")
  PROP_MP_G_0.05 <- count / total_count
  
  PROP <- 0.1
  
  # count total number of cases (G)
  tmp <- data
  
  total_count <- sum(tmp$cases == "1")
  
  # count total number of cases in fraction (G)
  tmp <- data %>%
    arrange(desc(rand)
    ) %>%
    arrange(desc(incidence_pred)
    ) %>%
    dplyr::slice_head(
      n = (PROP * nrow(data))
    ) %>%
    dplyr::filter(
      cases == "1"
    )
  count <- sum(tmp$cases == "1")
  PROP_MP_G_0.10 <- count / total_count
  
  PROP <- 0.2
  # count total number of cases (G)
  tmp <- data
  
  total_count <- sum(tmp$cases == "1")
  
  # count total number of cases in fraction (G)
  tmp <- data %>%
    arrange(desc(rand)
    ) %>%
    arrange(desc(incidence_pred)
    ) %>%
    dplyr::slice_head(
      n = (PROP * nrow(data))
    ) %>%
    dplyr::filter(
      cases == "1"
    )
  count <- sum(tmp$cases == "1")
  PROP_MP_G_0.20 <- count / total_count
  
  PROP <- 0.5
  # count total number of cases (G)
  tmp <- data
  
  total_count <- sum(tmp$cases == "1")
  
  # count total number of cases in fraction (G)
  tmp <- data %>%
    arrange(desc(rand)
    ) %>%
    arrange(desc(incidence_pred)
    ) %>%
    dplyr::slice_head(
      n = (PROP * nrow(data))
    ) %>%
    dplyr::filter(
      cases == "1"
    )
  count <- sum(tmp$cases == "1")
  PROP_MP_G_0.50 <- count / total_count
  
  param <- "MP-MP_PRESENCE_101-171_scat-model"
  
  MODEL <- c(param)
  PROP_MP_G_0.05 <- c(PROP_MP_G_0.05)
  PROP_MP_G_0.1 <- c(PROP_MP_G_0.10)
  PROP_MP_G_0.2 <- c(PROP_MP_G_0.20)
  PROP_MP_G_0.5 <- c(PROP_MP_G_0.50)
  
  new_row <- c(PROP_MP_G_0.05,PROP_MP_G_0.10,PROP_MP_G_0.20,PROP_MP_G_0.50)
  #new_row <- c(1,2,3,4)
  
  df_loop[val,] <- new_row
  
  # calculate mean for PROP 0.05 - 0.50
  PROP_MP_G_0.05_MEAN <- mean(df_loop$`0.05`)
  PROP_MP_G_0.10_MEAN <- mean(df_loop$`0.10`)
  PROP_MP_G_0.20_MEAN <- mean(df_loop$`0.20`)
  PROP_MP_G_0.50_MEAN <- mean(df_loop$`0.50`)
  
  df <- data.frame(MODEL,
                   PROP_MP_G_0.05_MEAN,
                   PROP_MP_G_0.10_MEAN,
                   PROP_MP_G_0.20_MEAN,
                   PROP_MP_G_0.50_MEAN)
  
}

write.table(df,
            sep = ",",
            file = toString(sprintf("MEAN_RAND-1-100_MP-G_scat-model_ranking.csv")),
            row.names = FALSE,
            quote = FALSE)


##############################################################
# calculate ranking for previous year incidence
##############################################################

##############################################################

# TEST meshblock19 MP-G

data <- meshblock2019_predictions_to_evaluate_DF %>%
  dplyr::filter(
    method == "meshblock2019"
  )

tmp_df <- data %>%
  arrange(desc(meshblock)
  )

all <- tmp_df[, c("meshblock")]
all <- data.frame(all)
INDEX <- data.frame(all)

x <- 1:10

for (val in x) {
  
  data$rand <- sample(100, size = nrow(data), replace = TRUE, )
  
  tmp <- data %>%
    arrange(desc(rand)
    ) %>%
    arrange(desc(pred_any)
    )
  
  tmp$seq <- 1:nrow(tmp)
  
  tmp <- tmp %>%
    arrange(desc(meshblock)
    )
  
  subset <- tmp[, c("seq")]
  
  all <- cbind(all, subset)
}

all <- subset(all, select = -c(all))

means <- data.frame(matrix(ncol = 1, nrow = nrow(all)))
means$means <- data.frame(rowMeans(all, na.rm = FALSE, dims = 1))

all_means <- cbind(INDEX$all, means$means)

top20 <- all_means %>% 
  distinct(INDEX$all, .keep_all = TRUE
  ) %>% 
  arrange(rowMeans.all..na.rm...FALSE..dims...1.
  ) %>% 
  dplyr::slice_head(n = (0.20 * nrow(data)))

write.table(top20$`INDEX$all`,
            sep = ",",
            file = toString(sprintf("TOP-20_MP-G_meshblock19.csv")),
            row.names = FALSE,
            col.names = FALSE,
            quote = FALSE)

##############################################################

data <- meshblock2019_predictions_to_evaluate_DF %>%
  dplyr::filter(
    method == "meshblock2019"
  )

x <- 1:100

# make df
df_loop <- data.frame(matrix(ncol = 4, nrow = 0))
colnames(df_loop) <- c("0.05", "0.10", "0.20", "0.50")

for (val in x) {
  
  data$rand <- sample(100, size = nrow(data), replace = TRUE, )
  
  PROP <- 0.05
  # count total number of cases (G)
  tmp <- data
  total_count <- sum(tmp$cases == "1")
  
  # count total number of cases in fraction (G)
  tmp <- data %>%
    arrange(desc(rand)
    ) %>%
    arrange(desc(pred_any)
    ) %>%
    dplyr::slice_head(
      n = (PROP * nrow(data))
    ) %>%
    dplyr::filter(
      cases == "1"
    )
  count <- sum(tmp$cases == "1")
  PROP_MP_G_0.05 <- count / total_count
  
  PROP <- 0.1
  
  # count total number of cases (G)
  tmp <- data
  
  total_count <- sum(tmp$cases == "1")
  
  # count total number of cases in fraction (G)
  tmp <- data %>%
    arrange(desc(rand)
    ) %>%
    arrange(desc(pred_any)
    ) %>%
    dplyr::slice_head(
      n = (PROP * nrow(data))
    ) %>%
    dplyr::filter(
      cases == "1"
    )
  count <- sum(tmp$cases == "1")
  PROP_MP_G_0.10 <- count / total_count
  
  PROP <- 0.2
  # count total number of cases (G)
  tmp <- data
  
  total_count <- sum(tmp$cases == "1")
  
  # count total number of cases in fraction (G)
  tmp <- data %>%
    arrange(desc(rand)
    ) %>%
    arrange(desc(pred_any)
    ) %>%
    dplyr::slice_head(
      n = (PROP * nrow(data))
    ) %>%
    dplyr::filter(
      cases == "1"
    )
  count <- sum(tmp$cases == "1")
  PROP_MP_G_0.20 <- count / total_count
  
  PROP <- 0.5
  # count total number of cases (G)
  tmp <- data
  
  total_count <- sum(tmp$cases == "1")
  
  # count total number of cases in fraction (G)
  tmp <- data %>%
    arrange(desc(rand)
    ) %>%
    arrange(desc(pred_any)
    ) %>%
    dplyr::slice_head(
      n = (PROP * nrow(data))
    ) %>%
    dplyr::filter(
      cases == "1"
    )
  count <- sum(tmp$cases == "1")
  PROP_MP_G_0.50 <- count / total_count
  
  param <- "MP-G_PRESENCE_101-171_meshblock19"
  
  MODEL <- c(param)
  PROP_MP_G_0.05 <- c(PROP_MP_G_0.05)
  PROP_MP_G_0.1 <- c(PROP_MP_G_0.10)
  PROP_MP_G_0.2 <- c(PROP_MP_G_0.20)
  PROP_MP_G_0.5 <- c(PROP_MP_G_0.50)
  
  new_row <- c(PROP_MP_G_0.05,PROP_MP_G_0.10,PROP_MP_G_0.20,PROP_MP_G_0.50)
  #new_row <- c(1,2,3,4)
  
  df_loop[val,] <- new_row
  
  # calculate mean for PROP 0.05 - 0.50
  PROP_MP_G_0.05_MEAN <- mean(df_loop$`0.05`)
  PROP_MP_G_0.10_MEAN <- mean(df_loop$`0.10`)
  PROP_MP_G_0.20_MEAN <- mean(df_loop$`0.20`)
  PROP_MP_G_0.50_MEAN <- mean(df_loop$`0.50`)
  
  df <- data.frame(MODEL,
                   PROP_MP_G_0.05_MEAN,
                   PROP_MP_G_0.10_MEAN,
                   PROP_MP_G_0.20_MEAN,
                   PROP_MP_G_0.50_MEAN)
  
}

write.table(df,
            sep = ",",
            file = toString(sprintf("MEAN_RAND-1-100_MP-G_meshblock19_ranking.csv")),
            row.names = FALSE,
            quote = FALSE)
