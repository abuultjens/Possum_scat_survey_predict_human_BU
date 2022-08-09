#!/bin/bash



# generate random prefix for all tmp files
RAND_1=`echo $((1 + RANDOM % 100))`
RAND_2=`echo $((100 + RANDOM % 200))`
RAND_3=`echo $((200 + RANDOM % 300))`
RAND=`echo "${RAND_1}${RAND_2}${RAND_3}"`

ls MP-MP*ranking.csv | cut -f 1-3 -d '_' > ${RAND}_fofn.txt


for PREFIX in $(cat ${RAND}_fofn.txt); do

		if ls ${PREFIX}_ranking.csv 1> /dev/null 2>&1; then

			# header
			head -1 ${PREFIX}_ranking.csv > ${RAND}_header1.csv
			cut -f 1 -d ',' ${PREFIX}_stats.csv | tr '\n' ',' | sed 's/.$//' > ${RAND}_header2.csv
			echo "AUC" > ${RAND}_header3.csv
			paste ${RAND}_header1.csv ${RAND}_header2.csv ${RAND}_header3.csv | tr '\t' ',' > ${RAND}_header.csv

			# loop
			tail -1 ${PREFIX}_ranking.csv > ${RAND}_tmp1.csv
			cut -f 2 -d ',' ${PREFIX}_stats.csv | tr '\n' ',' | sed 's/.$//' > ${RAND}_tmp2.csv
			paste ${RAND}_tmp1.csv ${RAND}_tmp2.csv ${PREFIX}_AUC.csv | tr '\t' ',' >> ${RAND}_body.csv

		fi

done

cat ${RAND}_header.csv > report.csv		
cat ${RAND}_body.csv >> report.csv

rm ${RAND}_*
