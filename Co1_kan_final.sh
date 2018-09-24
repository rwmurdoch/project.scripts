
#!/bin/bash

############################################################################
##  This script will create an OTU table and list of 
##  Actual Sequence Variants (OTU representative sequences) via dada2
##
##  This script does NOT do any taxonomic classification
##  
##  This script will
##  1. Import your data
##  2. Direct it through dada2 to generate "actual sequence variants"
##  3. exports the list of sequences and OTU-table
##  
##
##  This script MUST be customized to your own data
##  Make sure to read through it and adjust accordingly
##  Major points of required customization should be pointed out
##  Before Starting:
##  1. create a folder to work within
##  2. in that folder, make a folder with the same name as your project
##  3. place all of your raw sequencing reads into the subfolder
##  4. each data element is prepended by "zeale"; change "zeale" to something
##  unique to your study (bulk find and replace) and you should be clear to go
##  just remember to activate (remove "#") or deactivate (prepend with "#")
##  sections that you want to run or not run accordingly
##  Also, if you are running this on another computer, change the thread calls
##  Search and replace "24" with your desired thread call
##  note also that this pipeline is designed for the 341f 785r primer set
##  trying with a different primer set will not work
############################################################################




############################################################################
########################### main data import ###############################
############################################################################

qiime tools import \
--type 'SampleData[PairedEndSequencesWithQuality]' \
--input-path zeale \
--source-format CasavaOneEightSingleLanePerSampleDirFmt \
--output-path zealereads.qza

qiime demux summarize \
--i-data zealereads.qza \
--o-visualization zeale-demux.qzv \
--verbose



#1#
#remove the primers#
#you MUST customize with YOUR primers

qiime cutadapt trim-paired \
--i-demultiplexed-sequences zealereads.qza \
--p-cores 8 \
--p-front-f AGATATTGGAACWTTATATTTTATTTTTGG \
--p-front-r WACTAATCAATTWCCAAATCCTCC \
--o-trimmed-sequences zeale-data-cutadapt \
--verbose


############################################################################
# the dada2 pipeline, results in an otu table which can then be classified #
############################################################################

## this uses the cutadapt output ##
## dada2 does paired-end merging, quality filtering and chimera checking
## along with denoising and ASV(OTU) generation

qiime dada2 denoise-paired \
--i-demultiplexed-seqs zeale-data-cutadapt.qza \
--o-table zeale-dada2-table \
--o-representative-sequences zeale-dada2_seqs \
--o-denoising-stats zeale-data2-stats \
--p-n-threads 6 \
--p-trunc-len-f 0 \
--p-trunc-len-r 0

qiime feature-table summarize \
--i-table zeale-dada2-table.qza \
--o-visualization zeale-dada2-seq-stats \
--verbose

##################################################################
##  Exporting Data ##
##################################################################


## export the OTU table in biom format ##
## this biom seems unreadable, cannot import to CLC or to phyloseq

qiime tools export \
  zeale-dada2-table.qza \
  --output-dir exports


## turn the biom into a feature table, a.k.a. OTU table

biom convert -i exports/feature-table.biom -o \
exports/table.from_biom.txt --to-tsv

## now we need a list of sequences a.k.a. observations and their sequence
qiime tools export \
zeale-dada2_seqs.qza \
--output-dir exports

## you can use the online service 
## @ http://sequenceconversion.bugaco.com/converter/biology/sequences/tab_to_fasta.php
## to easily convert this to a tabular format

## Now in Excel, you can paste in the feature table and OTU table, then use VLOOKUP
## to build a classic OTU table if you like



