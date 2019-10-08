# A simple rapid command for harvesting rRNA genes from a genome fasta
# I run this from a dedicated conda environment which has bedtools and hmmer

barrnap -t 8 -o output.rRNA.fa YOURGENOME > RNA.gff
