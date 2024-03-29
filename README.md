# Possum_scat_survey_predict_human_BU
Statistical modelling using pathogen presence in possum scat surveys to predict the emergence of Buruli ulcer cases in humans. A manuscript describing this approach and its use can be found at https://elifesciences.org/articles/84983  
  
# Data files
  
### SatScan files  
  
```   
Bernoulli summer:  
SatScan/Satscan_Bernoulli_summer_cases.txt  
SatScan/Satscan_Bernoulli_summer_contr.txt  
SatScan/Satscan_Bernoulli_summer_geo.txt  
SatScan/Satscan_Bernoulli_summer_satscan_project.prm  
  
Bernoulli winter:  
SatScan/Satscan_Bernoulli_winter_plus_HR_cases.txt  
SatScan/Satscan_Bernoulli_winter_plus_HR_contr.txt  
SatScan/Satscan_Bernoulli_winter_plus_HR_geo.txt  
SatScan/Satscan_Bernoulli_winter_plus_HR_satscan_project.prm  
  
Poisson summer:  
SatScan/Satscan_Poisson_summer.cas  
SatScan/Satscan_Poisson_summer.geo  
SatScan/Satscan_Poisson_summer.pop  
SatScan/Satscan_Poisson_summer_Satscan_project.prm  
  
Poisson winter:  
SatScan/Satscan_Poisson_winter.cas  
SatScan/Satscan_Poisson_winter.geo  
SatScan/Satscan_Poisson_winter.pop  
SatScan/Satscan_Poisson_winter_Satscan_project_file.prm  
```  
  
 
### Spatial model files
  
``` 
uncompress spatial data folders   
tar -xf data/MB_2011_VIC_Census_counts_Centroids_LatLong.tar.gz -C data/  
tar -xf data/MB_2011_VIC_Census_counts_Centroids_LatLong_MorPen_Only.tar.gz -C data/  
  
Mornington Peninsula scat data:  
data/20210811_Extract.xlsx  
  
Geelong scat data:  
data/20210811_Extract_GEELONG_ONLY.xlsx  
  
Possum abundance data:  
data/pred_abund_quadcorrect_28May.tif  
  
Victorian Buruli ulcer case data:  
data/cases_MB_YEAR.xlsx  
  
Mornington Peninsula spatial data:  
data/MB_2011_VIC_Census_counts_Centroids_LatLong_MorPen_Only  
  
Geelong spatial data:  
data/MB_2011_VIC_Census_counts_Centroids_LatLong  

```

# Dependencies  
  
```  
R version 4.1.2   
flexclust_1.4.0
raster_3.5.15
readxl_1.4.0
sf_1.0.7
tidyverse_1.3.1
```  
  
Instructions on installing greta  
https://cran.r-project.org/web/packages/greta/vignettes/get_started.html  
  
# Scripts

### Run cross-validation on Mornington Peninsula data
```  
Rscript MP-MP.R  

outfiles:  
2018_MP-MP_previous_year_incidence_AUC.csv  
MEAN_RAND-1-100_MP-MP_meshblock18_ranking.csv  
MP-MP_PRESENCE_101-171_AB-DATA_AUC.csv  
MEAN_RAND-1-100_MP-MP_scat-model_ranking.csv  
```  

### Run trained model on previously unseen Geelong data
```  
Rscript MP-G.R  
  
outfiles:  
2019_MP-G_previous_year_incidence_AUC.csv  
MEAN_RAND-1-100_MP-G_meshblock19_ranking.csv  
MP-G_US-1_PRESENCE_101-171_AB-DATA_AUC.csv  
MEAN_RAND-1-100_MP-G_scat-model_ranking.csv  
```  


