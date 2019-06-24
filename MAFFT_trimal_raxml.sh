#!/bin/bash

#A simple step to align, trim, and build an ML tree using RaxML
#note that such an ML tree can take a very very long time to build 

mafft --auto new.and.old.RDases.fasta > new.and.old.align.fasta

/home/robert/Tools/trimal.v1.2rev59/trimAl/source/trimal \
-in new.and.old.align.fasta \
-out new.and.old.trim.fasta \
-gappyout

raxmlHPC -f a -m PROTGAMMALG -p 23 -x 23 -T 8 -s new.and.old.trim.fasta -n bajathor_proven_rdh.tree -# autoMRE
