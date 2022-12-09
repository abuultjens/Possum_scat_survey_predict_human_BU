
# Build model on MP data and predict on MP data with cross validation

# load packages
library(sf)
library(raster) 
library(tidyverse) 
library(readxl) 
library(flexclust) 

# load R scripts
source("R/load.R")


##############################################################################

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

# load in all scat locations and MU positivity
scat_positivity <- load_scat_positivity()

# subset to RT scats, and prepare for modelling, extracting possum densities
rt_scat_positivity <- prep_rt_scat_positivity(scat_positivity, possum_density)
# selects by season

# load in meshblock coordinates, cropping to peninsula
meshblocks <- load_meshblocks()

# load in residential BU cases and use 2016 populations and set upsample rate
cases <- load_cases()
# has all data including Geelong epi data

# assign survey periods and seasons
cases_survey_periods <- assign_survey_periods(cases)

cases_seasons <- assign_seasons(cases)

# plot cases_survey_periods
# plot_cases_by_period(cases_survey_periods)

# plot by season
# plot_cases_by_period(cases_seasons)

# compute incidence by meshblock, grouped by scat survey period
meshblock_incidence_survey_periods <- prep_meshblock_incidence(
  cases_survey_periods,
  meshblocks
)

# meshblock_incidence_survey_periods: 1840 x 7
meshblock_incidence_seasons <- prep_meshblock_incidence(
  cases_seasons,
  meshblocks
)

# plot meshblock incidence by season
# plot_meshblock_incidence_by_period(meshblock_incidence_seasons)

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
meshblock_incidence_survey_periods_blocked <- define_blocks(
  meshblock_incidence_survey_periods,
  n_blocks = n_cv_blocks
)

# plot these blocks
# plot_blocked_incidence(meshblock_incidence_survey_periods_blocked)

# split into training and testing sets
training <- split_data(
  meshblock_incidence_survey_periods_blocked,
  which = "train"
)

testing <- split_data(
  meshblock_incidence_survey_periods_blocked,
  which = "test"
)

# loop through fitting models (takes some time)
fitted_models <- lapply(training,
                        train_model,
                        rt_scat_positivity = rt_scat_positivity,
                        objective_type = "presence")


# loop through doing predictions to hold-out data
predictions <- mapply(FUN = predict_model,
                      fitted_model = fitted_models,
                      meshblocks = testing,
                      MoreArgs = list(
                        rt_scat_positivity = rt_scat_positivity
                      ),
                      SIMPLIFY = FALSE)

# combine
predictions_all <- do.call(bind_rows, predictions)

write.table(predictions_all,
            sep = ",",
            file = "predictions_all_MP-MP.csv",
            row.names = FALSE,
            quote = FALSE)

blocking <- predictions_all %>%
  st_drop_geometry() %>%
  select(
    meshblock,
    block
  ) %>%
  distinct()

##############################################################
# evaluate meshblock2018 previous year incidence model
##############################################################

previous_incidence <- meshblock_incidence_seasons %>%
  st_drop_geometry() %>%
  dplyr::filter(
    period == "2018",
    meshblock %in% predictions_all$meshblock
  ) %>%
  dplyr::left_join(
    blocking,
    by = "meshblock"
  ) %>%
  dplyr::rename(
    incidence_meshblock_2018 = incidence
  ) %>%
  dplyr::group_by(
    block
  ) %>%
  dplyr::mutate(
    incidence_block_2018 = sum(cases) / sum(pop)
  ) %>%
  dplyr::ungroup() %>%
  dplyr::select(
    meshblock,
    incidence_meshblock_2018,
    incidence_block_2018
  )

predictions_to_evaluate <- predictions_all %>%
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
    pred_annualincidence_meshblock2018 = incidence_meshblock_2018,
    pred_annualincidence_cvblock2018 = incidence_block_2018
  ) %>%
  mutate(
    pred_cases_model = incidence_pred * pop,
    pred_cases_meshblock2018 = incidence_meshblock_2018 * multiplier * pop,
    pred_cases_cvblock2018 = incidence_block_2018 * multiplier * pop
  ) %>%
  mutate(
    any = as.numeric(cases > 0),
    pred_any_model = prob_any_cases(pred_cases_model),
    pred_any_meshblock2018 = prob_any_cases(pred_cases_meshblock2018),
    pred_any_cvblock2018 = prob_any_cases(pred_cases_cvblock2018)
  ) %>%
  pivot_longer(
    cols = starts_with("pred_"),
    names_to = c(".value", "prediction"),
    names_pattern = "(.*)_(.*)"
  ) %>%
  select(
    period,
    block,
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
      levels = c("model", "meshblock2018", "cvblock2018")
    )
  )

# convert meshblock2019_predictions_to_evaluate to dataframe
meshblock2018_predictions_to_evaluate_DF <- predictions_to_evaluate %>%
  dplyr::filter(
    method == "meshblock2018"
  ) %>%
  as.data.frame()

# write meshblock2018_predictions_to_evaluate to file
write.table(meshblock2018_predictions_to_evaluate_DF,
            sep = ",",
            file = "meshblock2018_predictions_to_evaluate.csv",
            row.names = FALSE, 
            col.names = TRUE, 
            quote = FALSE)

###### calculate AUC for previous year incidence
data <- meshblock2018_predictions_to_evaluate_DF
tmp_AUC <- data %>%
  dplyr::summarise(
    auc_any = Metrics::auc(cases, pred_any)
  ) 

# write AUC for previous year incidence to file
write.table(tmp_AUC$auc_any[1],
            sep = ",",
            file = "2018_MP-MP_previous_year_incidence_AUC.csv",
            row.names = FALSE,
            col.names = FALSE)

##############################################################
# calculate ranking for previous year incidence
##############################################################

##############################################################

# TEST meshblock18 MP-MP

data <- data.frame(meshblock2018_predictions_to_evaluate_DF %>%
                     dplyr::filter(
                       method == "meshblock2018"
                     ))

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
            file = toString(sprintf("TOP-20_MP-MP_meshblock18.csv")),
            row.names = FALSE,
            col.names = FALSE,
            quote = FALSE)

##############################################################

data <- meshblock2018_predictions_to_evaluate_DF %>%
  dplyr::filter(
    method == "meshblock2018"
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
  
  # count total number of cases in fraction
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
  
  param <- "MP-MP_PRESENCE_101-171_meshblock18"
  
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
            file = toString(sprintf("MEAN_RAND-1-100_MP-MP_meshblock18_ranking.csv")),
            row.names = FALSE,
            quote = FALSE)

##############################################################
# evaluate scat-model
##############################################################

# scat-model AUC
data <- predictions_all
AUC <- data %>%
  as.data.frame() %>%
  dplyr::summarise(
    auc_any = Metrics::auc(cases, incidence_pred)
  ) 

write.table(AUC,
            sep = ",",
            file = toString("MP-MP_PRESENCE_101-171_AB-DATA_AUC.csv"),
            row.names = FALSE,
            col.names = FALSE)

# write predictions_to_evaluate_DF to file
predictions_to_evaluate_DF <- predictions_to_evaluate %>%
  dplyr::filter(
    method == "model"
  ) %>%
  as.data.frame()

write.table(predictions_to_evaluate_DF,
            sep = ",",
            file = toString("MP-MP_PRESENCE_101-171_AB-DATA_predictions_to_evaluate.csv"),
            row.names = FALSE,
            col.names = TRUE,
            quote = FALSE)

# write matrix and stats to csv
#cm <- confusionMatrix(
#  data = as.factor(round(predictions_to_evaluate_DF$pred_any)),
#  reference = as.factor(predictions_to_evaluate_DF$any)
#)

#stats <- cm$byClass
#write.table(stats,
#            sep = ",",
#            file = toString("MP-MP_PRESENCE_101-171_AB-DATA_stats.csv"),
#            row.names = TRUE,
#            col.names = FALSE,
#            quote = FALSE)

#matrix <- cm$table
#write.table(matrix,
#            sep = ",",
#            file = toString("MP-MP_PRESENCE_101-171_AB-DATA_matrix.csv"),
#            row.names = FALSE,
#            col.names = FALSE)

# write any and pred_any to csv
write.table(predictions_to_evaluate_DF$any,
            sep = ",",
            file = toString("MP-MP_PRESENCE_101-171_AB-DATA_any.csv"),
            row.names = FALSE,
            col.names = FALSE)

write.table(predictions_to_evaluate_DF$pred_any,
            sep = ",",
            file = toString("MP-MP_PRESENCE_101-171_AB-DATA_pred_any.csv"),
            row.names = FALSE,
            col.names = FALSE)

##############################################################
# calculate ranking for scat-model
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
            file = toString(sprintf("TOP-20_MP-MP_scat-model.csv")),
            row.names = FALSE,
            col.names = FALSE,
            quote = FALSE)

##############################################################

data <- predictions_all

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
  PROP_MP_G_0.1 <- c(PROP_MP_G_0.1)
  PROP_MP_G_0.2 <- c(PROP_MP_G_0.2)
  PROP_MP_G_0.5 <- c(PROP_MP_G_0.5)
  
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
            file = toString(sprintf("MEAN_RAND-1-100_MP-MP_scat-model_ranking.csv")),
            row.names = FALSE,
            quote = FALSE)


