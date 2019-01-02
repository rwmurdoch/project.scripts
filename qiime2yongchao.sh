#!/bin/bash

#########################################
## Adapting the Babu script to ###
## Yongchao's data  
## Dec 22, 2018                        
#########################################

## conda activate qiime2-2018.11 ##



qiime tools import \
--type 'SampleData[PairedEndSequencesWithQuality]' \
--input-path reads \
--input-format CasavaOneEightSingleLanePerSampleDirFmt \
--output-path yongchaoreads.qza

qiime demux summarize \
--i-data yongchaoreads.qza \
--o-visualization yongchao-demux.qzv \
--verbose


## trim the primers (341F/785R)
## stdout is directed to a logfile

qiime cutadapt trim-paired \
--i-demultiplexed-sequences yongchaoreads.qza \
--p-cores 8 \
--p-front-f CCTACGGGNGGCWGCAG \
--p-front-r GACTACHVGGGTATCTAATCC \
--o-trimmed-sequences yongchao-data-cutadapt \
--verbose > cutadapt_log.txt

###############################################
# training the feature classifier
###############################################

## ONLY RUN THIS ONE TIME, IT TAKES HOURS##

## I'll work with the  full-length silva132 database (seqs and taxonomy)
## downloaded from: https://forum.qiime2.org/t/silva-132-classifiers/3698/4 (distributed by Caporaso)
## Database is first trimmed using the same primers used for the study (341F/785R)

#qiime feature-classifier extract-reads \
#  --i-sequences 99-otus.qza \
#  --p-f-primer CCTACGGGNGGCWGCAG \
#  --p-r-primer GACTACHVGGGTATCTAATCC \
#  --o-reads ref-seqs.qza \
#  --verbose

#qiime feature-classifier fit-classifier-naive-bayes \
#--i-reference-reads ref-seqs.qza \
#--i-reference-taxonomy 7_level_taxonomy.qza \
#--o-classifier classifier.qza


#####################################
## dada2 and classification
####################################33333

qiime dada2 denoise-paired \
--i-demultiplexed-seqs yongchaoreads.qza \
--o-table yongchao-dada2-table \
--o-representative-sequences yongchao-dada2_seqs \
--o-denoising-stats yongchao-data2-stats \
--p-n-threads 6 \
--p-trunc-len-f 0 \
--p-trunc-len-r 0 \
--p-min-fold-parent-over-abundance 4 # this is the sensitivity of chimera detection; default led to 90% reads flagged as chimeric, which is not reasonable.  This is more strict, should remove fewer seqs

qiime feature-table summarize \
--i-table yongchao-dada2-table.qza \
--o-visualization yongchao-dada2-seq-stats \
--verbose

qiime feature-classifier classify-sklearn \
  --i-classifier classifier.qza \
  --i-reads yongchao-dada2_seqs.qza \
  --p-n-jobs 8 \
  --o-classification yongchao-dada2-taxonomy

qiime metadata tabulate \
  --m-input-file yongchao-dada2-taxonomy.qza \
  --o-visualization yongchao-dada2-taxonomy

qiime taxa barplot \
  --i-table yongchao-dada2-table.qza \
  --i-taxonomy yongchao-dada2-taxonomy.qza \
  --m-metadata-file yongchao_metadata.csv \
  --o-visualization yongchao-dada2-taxa-bar-plots

qiime feature-table summarize \
  --i-table yongchao-dada2-table.qza \
  --o-visualization yongchao-dada2-table.qzv \
  --m-sample-metadata-file yongchao_metadata.csv

qiime feature-table tabulate-seqs \
  --i-data yongchao-dada2_seqs.qza \
  --o-visualization yongchao-dada2_seqs.qzv

#######################################
# preparation for alpha div metrics
#######################################

qiime alignment mafft \
  --i-sequences yongchao-dada2_seqs.qza \
  --o-alignment yongchao-dada2_seqs-aligned.qza \
  --p-n-threads 8

qiime alignment mask \
 --i-alignment yongchao-dada2_seqs-aligned.qza \
--o-masked-alignment yongchao-dada2_seqs-aligned-masked.qza

qiime phylogeny fasttree \
 --i-alignment yongchao-dada2_seqs-aligned-masked.qza \
 --o-tree yongchao-unrooted-tree-dada2.qza

qiime phylogeny midpoint-root \
--i-tree yongchao-unrooted-tree-dada2.qza \
--o-rooted-tree yongchao-rooted-tree-dada2.qza

################################################
# generate core diversity metrics #
# pay close attention to the sampling depth command #
###################################################

qiime diversity core-metrics-phylogenetic \
  --i-phylogeny yongchao-rooted-tree-dada2.qza \
  --i-table yongchao-dada2-table.qza \
  --p-sampling-depth 30000 \
  --m-metadata-file yongchao_metadata.csv \
  --output-dir yongchao-core-metrics-results-dada2

## visualization of diversity metrics ##

qiime diversity alpha-rarefaction \
  --i-table yongchao-dada2-table.qza \
  --i-phylogeny yongchao-rooted-tree-dada2.qza \
  --p-min-depth 1 \
  --p-max-depth 30000 \
  --m-metadata-file yongchao_metadata.csv \
  --o-visualization yongchao-open-alpha-rarefaction-dada2.qzv

###############################################
# exporting data 
# you can easily export seqs and taxonomy directly out of
# their corresponding .qza files using the qiime tools export feature.
# to get the feature table, you export the table in biom format and then convert 
# into a simple text file 
#################################

qiime tools export --input-path yongchao-dada2-table.qza --output-path exports
qiime tools export --input-path yongchao-dada2_seqs.qza --output-path exports
qiime tools export --input-path yongchao-dada2-taxonomy.qza --output-path exports

biom convert -i exports/feature-table.biom \
-o exports/otu_table.txt --to-tsv

## combine everything into a single table
## this uses the R script create.OTU.table.R
## script is available here: https://github.com/rwmurdoch/project.scripts/blob/master/create.OTU.table.R
## download/copy the script into your project directory; it will read and write in the "export" directory

Rscript create.OTU.table.R
        
## combine various outputs into a results package

tar -cf results.tar.gz \
exports \
yongchao-core-metrics-results-dada2 \
yongchao-open-alpha-rarefaction-dada2.qzv \
yongchao-dada2-taxa-bar-plots.qzv \
yongchao_metadata.csv \
yongchao-dada2-seq-stats.qzv \
yongchao-demux.qzv
      




