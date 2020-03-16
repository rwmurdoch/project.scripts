#!/bin/bash
mkdir ../proteins
mkdir ../genes
mkdir ../prodigal
for f in ../genomes/*
	do
	name=${f##*/}
	prodigal -i $f \
	-a "../proteins/${name}" \
	-d "../genes/${name}" \
	-o "../prodigal/${name}"
done

