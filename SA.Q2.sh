#!/bin/bash

############################################################################
##  This script will create OTU tables via vsearch open reference clustering
##  
##  just remember to activate (remove "#") or deactivate (prepend with "#")
##  sections that you want to run or not run accordingly
##  Also, if you are running this on another computer, change the thread calls
##  Search and replace "24" with your desired thread call
##  note also that this pipeline is designed for the 341f 785r primer set
##  trying with a different primer set will not work
##
##  This script is tested with qiime2-2019.7 (does not work with older 
##  versions)
############################################################################




############################################################################
## Classifer Training #######
############################################################################

# you must download the ref databases and point --input-path accordingly
# this section is deactivated by default; only use it once!
# the OTUs and taxonomy files are provided at the Qiime2 website

#qiime feature-classifier fit-classifier-naive-bayes \
#--i-reference-reads ../99-otus-515-806.qza \
#--i-reference-taxonomy ../7_level_taxonomy.qza \
#--o-classifier ../classifier.qza



############################################################################
########################### main data import ###############################
############################################################################

## data is in single end format

## reads are already demultiplexed ##

qiime tools import \
--type 'SampleData[SequencesWithQuality]' \
--input-path ../reads \
--input-format CasavaOneEightSingleLanePerSampleDirFmt \
--output-path ../reads.qza

qiime demux summarize \
--i-data ../reads.qza \
--o-visualization ../demux.qzv \
--verbose


############################################################################
########Trimming and open reference clustering#################
############################################################################

#1#
#this is a strict quality filtering#

qiime quality-filter q-score \
--i-demux ../reads.qza \
--p-min-quality 20 \
--o-filtered-sequences ../qtrim-seqs \
--o-filter-stats ../qtrim-stats \
--verbose

# use this to check how many reads you are filtering out
# needs to be fine-tuned so that you are being careful
# but not throwing out too much data

qiime metadata tabulate \
--m-input-file ../qtrim-stats.qza \
--o-visualization ../qtrim-stats.qzv

#qiime tools view ../qtrim-stats.qzv


#2#
#this is required, creates a feature table#

qiime vsearch dereplicate-sequences \
  --i-sequences ../qtrim-seqs.qza \
  --o-dereplicated-table ../derep-table \
  --o-dereplicated-sequences ../derep-seqs

#3#
# chimera removal #

qiime vsearch uchime-denovo \
  --i-sequences ../derep-seqs.qza \
  --i-table ../derep-table.qza \
  --o-chimeras ../chimera-seqs \
  --o-nonchimeras ../nonchimera-seqs \
  --o-stats ../chimera-stats

# after separating chimeras, i have to filter the input data, removing chimeras#

qiime feature-table filter-features \
  --i-table ../derep-table.qza \
  --m-metadata-file ../chimera-seqs.qza \
  --p-exclude-ids \
  --o-filtered-table ../chim-filtered-table.qza

qiime feature-table filter-seqs \
  --i-data ../derep-seqs.qza \
  --m-metadata-file ../chimera-seqs.qza \
  --p-exclude-ids \
  --o-filtered-data ../chim-filtered-seqs.qza

qiime feature-table summarize \
  --i-table ../chim-filtered-table.qza \
  --o-visualization ../chim-filtered-table.qzv

#qiime tools view ../chim-filtered-table.qzv

#4#
#this is the clustering but does not actually create a taxonomy table#
#essentially, clusters are created primarily using the ref database as seed

qiime vsearch cluster-features-open-reference \
--i-sequences ../chim-filtered-seqs.qza \
--i-table ../chim-filtered-table.qza \
--i-reference-sequences ../99-otus-515-806.qza \
--p-perc-identity 0.99 \
--p-threads 8 \
--o-clustered-table ../OTU-table \
--o-clustered-sequences ../OTU-seqs \
--o-new-reference-sequences ../open-OTU-ref-seqs

# 4 #
# sequence taxonomic classification #

qiime feature-classifier classify-sklearn \
--i-classifier ../classifier.qza \
--p-n-jobs 2 \
--p-reads-per-batch 200 \
--i-reads ../OTU-seqs.qza \
--o-classification ../OTU-taxonomy

#filter conataminants
qiime taxa filter-table \
--i-taxonomy ../OTU-taxonomy.qza \
--i-table ../OTU-table.qza \
--p-exclude mitochondria,chloroplast \
--o-filtered-table ../OTU-table.qza

# 5 #
# make bar charts #

qiime metadata tabulate \
  --m-input-file ../Sample_metadata.txt \
  --o-visualization ../OTU-taxonomy.qzv

qiime taxa barplot \
  --i-table ../OTU-table.qza \
  --i-taxonomy ../OTU-taxonomy.qza \
  --m-metadata-file ../Sample_metadata.txt \
  --o-visualization ../taxa-bar-plots.qzv


# 6 #
# work towards alpha diversity analysis, first build a tree #

qiime feature-table summarize \
  --i-table ../OTU-table.qza \
  --o-visualization ../OTU-table.qzv \
  --m-sample-metadata-file ../Sample_metadata.txt

qiime feature-table tabulate-seqs \
  --i-data ../OTU-seqs.qza \
  --o-visualization ../OTU-seqs.qzv

qiime alignment mafft \
  --i-sequences ../OTU-seqs.qza \
  --o-alignment ../aligned.qza \
  --p-n-threads 8

qiime alignment mask \
  --i-alignment ../aligned.qza \
  --o-masked-alignment ../aligned-masked.qza

qiime phylogeny fasttree \
  --i-alignment ../aligned-masked.qza \
  --o-tree ../unrooted-tree.qza

qiime phylogeny midpoint-root \
--i-tree ../unrooted-tree.qza \
--o-rooted-tree ../rooted-tree.qza

# 7 #
# generate core diversity metrics #
# pay close attention to the sampling depth command #

qiime diversity core-metrics-phylogenetic \
  --i-phylogeny ../rooted-tree.qza \
  --i-table ../OTU-table.qza \
  --p-sampling-depth 400 \
  --m-metadata-file ../Sample_metadata.txt \
  --output-dir ../core-metrics-results

## visualization of diversity metrics ##

qiime diversity alpha-rarefaction \
  --i-table ../OTU-table.qza \
  --i-phylogeny ../rooted-tree.qza \
  --p-min-depth 1 \
  --p-max-depth 400 \
  --m-metadata-file ../Sample_metadata.txt \
  --o-visualization ../alpha-rarefaction.qzv

## additional diveristy metrics

qiime diversity alpha \
--i-table ../OTU-table.qza \
--p-metric chao1 \
--o-alpha-diversity ../chao1_vector.qza

qiime diversity alpha \
--i-table ../OTU-table.qza \
--p-metric goods_coverage \
--o-alpha-diversity ../goods_coverage_vector.qza


###############################################
# exporting data 
# you can easily export seqs and taxonomy directly out of
# their corresponding .qza files using the qiime tools export feature.
# to get the feature table, you export the table in biom format and then convert 
# into a simple text file 
#################################

qiime tools export --input-path ../OTU-table.qza --output-path ../exports
qiime tools export --input-path ../OTU-seqs.qza --output-path ../exports
qiime tools export --input-path ../OTU-taxonomy.qza --output-path ../exports

biom convert -i ../exports/feature-table.biom \
-o ../exports/otu_table.txt --to-tsv

## combine everything into a single table
## this uses the R script create.OTU.table.R
## script is available here: https://github.com/rwmurdoch/project.scripts/blob/master/create.OTU.table.R
## download/copy the script into your project directory; it will read and write in the "export" directory

Rscript create.OTU.table.R

# this section pulls each of the 7-level taxonomy tables from
# the taxa-bar-plots artifact, transposes them, and removes the last
# line, which represents metadata

qiime tools export --input-path ../taxa-bar-plots.qzv --output-path ../taxonomy_levels
mkdir ../temp

for f in ../taxonomy_levels/*.csv
	do
	name=${f##*/}
	csvtool transpose "$f" > ../temp/"${name}"
done

for f in ../temp/*
	do
	name=${f##*/}
	sed '$d' "$f" > ../exports/"${name}"
done



## combine various outputs into a results package

tar -cf ../results.tar.gz \
../exports \
../core-metrics-results \
../alpha-rarefaction.qzv \
../taxa-bar-plots.qzv \
../Sample_metadata.txt \
../per-sample-fastq-counts.csv \
../qtrim.stats.csv \
../scripts
