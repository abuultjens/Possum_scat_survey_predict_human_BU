# Possum_scat_survey_predict_human_BU
Statistical modelling using pathogen presence in possum scat surveys to predict BU cases in humans

# Data files


# Scripts
```  
MP-MP_RUNNER.sh [upsample_rate] [cutoff-distance]  
  
runs:  
MP-MP.R  
```  
  
```  
MP-G_RUNNER.sh [upsample_rate] [cutoff-distance]  
  
runs:  
MP-G.R  
```  

```  
MP-MP_RUNNER_RAND-1-100.sh  
    
runs:  
MP-G_RUNNER_RAND-1-100.sh  
```  

```  
report-maker.sh  
```  

### Determine model with greatest AUC
```  
tail -n +2 report.csv | sort -t ',' -k 17 -nr | head -1 | cut -f 1 -d ','  
```  

