#!/bin/bash
#template for adding fragments to an existing tree 
#note that you must have the original alilgnment and tree files

mafft –addfragments \
trees/Fragment_placement/KUB_arch.fa \
–reorder –thread -1 \
trees/SSU_ref_seqs/SSU_97.trim > trees/Fragment_placement/SSU97_addfrag.align 

raxmlHPC -f v -m GTRGAMMAI -p 23 \
-t trees/SSU_ref_seqs/IQTree_jan30/SSU_97.trim.treefile \
-s trees/Fragment_placement/SSU97_addfrag.align \
-n trees/Fragment_placement/SSU97_fragtree
