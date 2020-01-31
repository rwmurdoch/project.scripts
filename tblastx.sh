#!/bin/bash
#a simple script for scanning a transcriptome assembly with a custom local database

makeblastdb -in ../tblastx/DHB.fna -dbtype nucl -out ../tblastx/blastdb/mec_db

for f in ../tblastx/queries/*
	do
	name=${f##*/}
	tblastx \
	-db ../tblastx/blastdb/mec_db \
	-out ../tblastx/results/"${name}".blast.out \
	-query "$f" \
	-outfmt 6 \
	-evalue 0.001	
done
