#!/bin/bash

# Build model on MP data and predict on MP data with cross validation

for US in $(cat US_list.txt); do

        for CD in $(cat CD_list.txt); do

		PREFIX=MP-MP_US-${US}_CD-${CD}

		Rscript MP-MP.R \
			${US} \
			${CD} \
			data/20210811_Extract4Nick.csv \
			${PREFIX}_predictions_to_evaluate.csv \
			${PREFIX}_AUC.csv \
			${PREFIX}_stats.csv \
			${PREFIX}_matrix.csv \
			${PREFIX}_any.csv \
			${PREFIX}_pred_any.csv \
			${PREFIX} \
			${PREFIX}_ranking.csv
        
	done

done
