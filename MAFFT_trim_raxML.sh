#!/bin/bash

#a simple script to build a "besttree" with raxml
#this is NOT bootstrapped and should only be used for exploratory purposes

mafft --auto new.and.old.RDases.fasta > new.and.old.align.fasta

/home/robert/Tools/trimal.v1.2rev59/trimAl/source/trimal \
-in new.and.old.align.fasta \
-out new.and.old.trim.fasta \
-gappyout

raxmlHPC -m PROTGAMMALG -p 23 -T 8 -s new.and.old.trim.fasta -n bajathor_proven_rdh.tree
