# Possum_scat_survey_predict_human_BU
Statistical modelling using pathogen presence in possum scat surveys to predict BU cases in humans

# Data files

```  
20210811_Extract4Nick.csv  
20210811_Extract4Nick_GEELONG_ONLY.xlsx  
'BU NHMRC NickGolding SpatialEpi data NO PHESSID_Jan to 9 Nov 2021.xlsx'  
'BU NHMRC NickGolding SpatialEpi data NO PHESSID_upd 26 Nov 2019.xlsx'  
'BU NHMRC NickGolding SpatialEpi data with NO PHESSID_2019 and 2020.xlsx'  
MB_2011_VIC_Census_counts_Centroids_LatLong  
MB_2011_VIC_Census_counts_Centroids_LatLong_MorPen_Only  
MP_RAND  
pred_abund_quadcorrect_28May.tif  
```


```  
US_list.txt  
CD_list.txt  
```

# Scripts

### Run cross-validation on Mornington Peninsula data
```  
sh MP-MP_RUNNER.sh
  
runs:  
MP-MP.R  

outfiles:
  
```  
 
### Generate cross-validation report

```  
sh report-maker.sh  

outfile:  
report.csv  
```  

### Determine model with greatest AUC
```  
tail -n +2 report.csv | sort -t ',' -k 17 -nr | head -1 | cut -f 1 -d ','  
```  

### Run best model on previously unseen Geelong data
```  
sh MP-G_RUNNER.sh [upsample_rate] [cutoff-distance]  
  
runs:  
MP-G.R  
```  

### Run best model with randomised scat location information

```  
sh MP-MP_RUNNER_RAND-1-100.sh [upsample_rate] [cutoff-distance]  
  
runs:  
MP-MP.R  
    
 
sh MP-G_RUNNER_RAND-1-100.sh [upsample_rate] [cutoff-distance]  
  
runs:  
MP-G.R  
```  


