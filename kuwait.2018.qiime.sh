#!/bin/bash

#########################################
## Adapting the latest Kan script to ###
## Babu's data  
## Sept 24, 2018                        
#########################################

# Only use your main data import once
# deactivated by default

qiime tools import \
--type 'SampleData[PairedEndSequencesWithQuality]' \
--input-path Babu_Kuwait_9_2018 \
--source-format CasavaOneEightSingleLanePerSampleDirFmt \
--output-path babureads.qza

qiime demux summarize \
--i-data babureads.qza \
--o-visualization babu-demux.qzv \
--verbose


## reads have already been trimmed by Dan ##
## this step is not necessary 

#qiime cutadapt trim-paired \
#--i-demultiplexed-sequences babureads.qza \
#--p-cores 8 \
#--p-front-f GTGYCAGCMGCCGCGGTAA \
#--p-front-r GGACTACHVGGGTWTCTAAT \
#--o-trimmed-sequences babu-data-cutadapt \
#--verbose

###############################################
# training the feature classifier
###############################################

## I'll work with the pretrained and trimmed classifier
## downloaded from: https://forum.qiime2.org/t/silva-132-classifiers/3698
## these training steps are not required

#qiime feature-classifier extract-reads \
#  --i-sequences silva-132-99-nb-classifier.qza \
#  --p-f-primer GTGYCAGCMGCCGCGGTAA \
#  --p-r-primer GGACTACHVGGGTWTCTAAT \
#  --o-reads ref-seqs.qza \
#  --verbose

#qiime feature-classifier fit-classifier-naive-bayes \
#--i-reference-reads BOLD_arth_100-seqs.qza \
#--i-reference-taxonomy ref-taxonomy.qza \
#--o-classifier classifier.qza


#####################################
## dada2 and classification
####################################33333

qiime dada2 denoise-paired \
--i-demultiplexed-seqs babureads.qza \
--o-table babu-dada2-table \
--o-representative-sequences babu-dada2_seqs \
--o-denoising-stats babu-data2-stats \
--p-n-threads 8 \
--p-trunc-len-f 0 \
--p-trunc-len-r 0

qiime feature-table summarize \
--i-table babu-dada2-table.qza \
--o-visualization babu-dada2-seq-stats \
--verbose

qiime feature-classifier classify-sklearn \
  --i-classifier silva-132-99-515-806-nb-classifier.qza \
  --i-reads babu-dada2_seqs.qza \
  --p-n-jobs 8 \
  --o-classification babu-dada2-taxonomy

qiime metadata tabulate \
  --m-input-file babu-dada2-taxonomy.qza \
  --o-visualization babu-dada2-taxonomy

qiime taxa barplot \
  --i-table babu-dada2-table.qza \
  --i-taxonomy babu-dada2-taxonomy.qza \
  --m-metadata-file babu_metadata.csv \
  --o-visualization babu-dada2-taxa-bar-plots

qiime feature-table summarize \
  --i-table babu-dada2-table.qza \
  --o-visualization babu-dada2-table.qzv \
  --m-sample-metadata-file babu-dada2-table.qza

qiime feature-table tabulate-seqs \
  --i-data babu-dada2_seqs.qza \
  --o-visualization babu-dada2_seqs.qzv

#######################################
# preparation for alpha div metrics
#######################################

qiime alignment mafft \
  --i-sequences babu-dada2_seqs.qza \
  --o-alignment babu-dada2_seqs-aligned.qza \
  --p-n-threads 8

qiime alignment mask \
 --i-alignment babu-dada2_seqs-aligned.qza \
--o-masked-alignment babu-dada2_seqs-aligned-masked.qza

qiime phylogeny fasttree \
 --i-alignment babu-dada2_seqs-aligned-masked.qza \
 --o-tree babu-unrooted-tree-dada2.qza

qiime phylogeny midpoint-root \
--i-tree babu-unrooted-tree-dada2.qza \
--o-rooted-tree babu-rooted-tree-dada2.qza

################################################
# generate core diversity metrics #
# pay close attention to the sampling depth command #
###################################################

qiime diversity core-metrics-phylogenetic \
  --i-phylogeny babu-rooted-tree-dada2.qza \
  --i-table babu-dada2-table.qza \
  --p-sampling-depth 100000 \
  --m-metadata-file babu_metadata.csv \
  --output-dir babu-core-metrics-results-dada2

## visualization of diversity metrics ##

qiime diversity alpha-rarefaction \
  --i-table babu-dada2-table.qza \
  --i-phylogeny babu-rooted-tree-dada2.qza \
  --p-min-depth 1 \
  --p-max-depth 300000 \
  --m-metadata-file babu_metadata.csv \
  --o-visualization babu-open-alpha-rarefaction-dada2.qzv

###############################################
# exporting data 
# you can grab the seqs and taxonomy directly out of
# their corresponding .qza files
# you will need to convert the table, which is
# in .biom format into a simple text file however
#################################

qiime tools export babu-dada2-table.qza --output-dir exports

biom convert -i exports/feature-table.biom \
-o exports/otu_table.txt --to-tsv



