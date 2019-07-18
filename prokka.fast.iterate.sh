#!/bin/bash

# this was run over the a set of 500 MAGs
# primary purpose was to obtain proteins from the MAGs

mkdir spruce_annot

for f in SPRUCE_MAGs/dREP_genomes/*
    do
    name=${f##*/}
    tag=`sed 's/SPRUCE.//g' <<<"$name"`
    tag=`sed 's/.fa//g' <<<"$tag"`
    prokka --compliant --locustag "$tag" \
    --outdir spruce_annot/"${tag}" \
    --prefix "$tag" \
    -force \
    --fast --norrna --notrna \
    "$f"
done
