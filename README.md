# Possum_scat_survey_predict_human_BU
Statistical modelling using pathogen presence in possum scat surveys to predict BU cases in humans

# Data files

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

## Model parameter lists
```  
US_list.txt  
CD_list.txt  
```

# Scripts

### Run cross-validation on Mornington Peninsula data
```  
command:  
sh MP-MP_RUNNER.sh
  
runs:  
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
 
### Generate cross-validation report

```  
command:  
sh report-maker.sh  

outfile:  
report.csv  
```  

### Determine model with greatest AUC
```  
command:  
tail -n +2 report.csv | sort -t ',' -k 17 -nr | head -1 | cut -f 1 -d ','  
```  

### Run best model on previously unseen Geelong data
```  
command:  
sh MP-G_RUNNER.sh [upsample_rate] [cutoff-distance]  
  
runs:  
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

### Run best model with randomised scat location information

``` 
command:  
sh MP-MP_RUNNER_RAND-1-100.sh [upsample_rate] [cutoff-distance]  
  
runs:  
MP-MP.R  
  
outfiles:  
MP-MP_US-[US]_CD-[CD]_RAND-REP-[REP]_AUC.csv  
MP-MP_US-[US]_CD-[CD]_RAND-REP-[REP]_predictions_to_evaluate.csv  
MP-MP_US-[US]_CD-[CD]_RAND-REP-[REP]_stats.csv  
MP-MP_US-[US]_CD-[CD]_RAND-REP-[REP]_matrix.csv  
MP-MP_US-[US]_CD-[CD]_RAND-REP-[REP]_any.csv  
MP-MP_US-[US]_CD-[CD]_RAND-REP-[REP]_pred_any.csv  
MP-MP_US-[US]_CD-[CD]_RAND-REP-[REP]_ranking.csv  
  
command:   
sh MP-G_RUNNER_RAND-1-100.sh [upsample_rate] [cutoff-distance]  
  
runs:  
MP-G.R  
  
outfiles:
MP-G_US-[US]_CD-[CD]_RAND-REP-[REP]_AUC.csv  
MP-G_US-[US]_CD-[CD]_RAND-REP-[REP]_predictions_to_evaluate.csv  
MP-G_US-[US]_CD-[CD]_RAND-REP-[REP]_stats.csv  
MP-G_US-[US]_CD-[CD]_RAND-REP-[REP]_matrix.csv  
MP-G_US-[US]_CD-[CD]_RAND-REP-[REP]_any.csv  
MP-G_US-[US]_CD-[CD]_RAND-REP-[REP]_pred_any.csv  
MP-G_US-[US]_CD-[CD]_RAND-REP-[REP]_ranking.csv  
```  


