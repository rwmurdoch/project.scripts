# script for creating a blast database and searching
# this is tailored for very short query searches, such as primers

#!/bin/bash

makeblastdb -in DEFO.genome.fna -dbtype nucl -out blastdb/defo_genome

cp DEFO.genome.fna blastdb/defo_genome.fasta

blastn \
-db blastdb/defo_genome \
-out defo.genome.newprimers.blast.out \
-query mecEF.new.primer.fasta \
-outfmt 6 \
-evalue 1 \
-word_size 5
