#!/bin/bash


US=$1
CD=$2

for REP in {1..100}; do

	PREFIX=MP-MP_US-${US}_CD-${CD}_RAND-REP-${REP}

	Rscript MP-MP.R \
	${US} \
	${CD} \
	data/MP_RAND/20210811_Extract4Nick_RAND-${REP}.csv \
	${PREFIX}_predictions_to_evaluate.csv \
	${PREFIX}_AUC.csv \
	${PREFIX}_stats.csv \
	${PREFIX}_matrix.csv \
	${PREFIX}_any.csv \
	${PREFIX}_pred_any.csv \
	${PREFIX} \
	${PREFIX}_ranking.csv
        
done

