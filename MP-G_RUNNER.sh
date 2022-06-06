#!/bin/bash

# Build model on MP data and then predict on G data

US=$1
CD=$2

PREFIX=MP-G_US-${US}_CD-${CD}

Rscript MP-G.R \
  ${US} \
  ${CD} \
  data/20210811_Extract4Nick.csv \
  ${PREFIX}_MP-MP_MODEL.RDS \
  ${PREFIX}_MP-G_MODEL.RDS \
  ${PREFIX}_predictions_to_evaluate.csv \
  ${PREFIX}_AUC.csv \
  ${PREFIX}_stats.csv \
  ${PREFIX}_matrix.csv \
  ${PREFIX}_any.csv \
  ${PREFIX}_pred_any.csv \
  ${PREFIX} \
  ${PREFIX}_ranking.csv

