# Possum_scat_survey_predict_human_BU
Statistical modelling using pathogen presence in possum scat surveys to predict the emergence of BU cases in humans.
  
# Data files
```  
# uncompress spatial data folders   
tar -xf data/MB_2011_VIC_Census_counts_Centroids_LatLong.tar.gz -C data/  
tar -xf data/MB_2011_VIC_Census_counts_Centroids_LatLong_MorPen_Only.tar.gz -C data/  
```
  
```  
Mornington Peninsula scat data:  
data/20210811_Extract4Nick.csv  
  
Geelong scat data:  
data/20210811_Extract4Nick_GEELONG_ONLY.xlsx  
  
Possum abundance data:  
data/pred_abund_quadcorrect_28May.tif  
  
Victorian Buruli ulcer case data:  
data/'BU NHMRC NickGolding SpatialEpi data NO PHESSID_Jan to 9 Nov 2021.xlsx'  
data/'BU NHMRC NickGolding SpatialEpi data NO PHESSID_upd 26 Nov 2019.xlsx'  
data/'BU NHMRC NickGolding SpatialEpi data with NO PHESSID_2019 and 2020.xlsx'  
  
Mornington Peninsula spatial data:  
data/MB_2011_VIC_Census_counts_Centroids_LatLong_MorPen_Only  
  
Geelong spatial data:  
data/MB_2011_VIC_Census_counts_Centroids_LatLong  
  
Mornington Peninsula scat data with randomised location information:  
data/MP_RAND/20210811_Extract4Nick_RAND-[1-100].csv  

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
MP-MP.R  

outfiles:
MP-MP_US-[US]_CD-[CD]_AUC.csv  
MP-MP_US-[US]_CD-[CD]_predictions_to_evaluate.csv  
MP-MP_US-[US]_CD-[CD]_stats.csv  
MP-MP_US-[US]_CD-[CD]_matrix.csv  
MP-MP_US-[US]_CD-[CD]_any.csv  
MP-MP_US-[US]_CD-[CD]_pred_any.csv  
MP-MP_US-[US]_CD-[CD]_ranking.csv  
```  

### Run trained model on previously unseen Geelong data
```  

MP-G.R  
  
outfiles:  
MP-G_US-[US]_CD-[CD]_AUC.csv  
MP-G_US-[US]_CD-[CD]_predictions_to_evaluate.csv  
MP-G_US-[US]_CD-[CD]_stats.csv  
MP-G_US-[US]_CD-[CD]_matrix.csv  
MP-G_US-[US]_CD-[CD]_any.csv  
MP-G_US-[US]_CD-[CD]_pred_any.csv  
MP-G_US-[US]_CD-[CD]_ranking.csv  
```  


