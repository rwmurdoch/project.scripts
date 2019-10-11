# combine fastq files for the sake of pooling replicate 16S amplicon libraries

#!/bin/bash

S1=(../coastal.demultiplexed/S1/*)
S2=(../coastal.demultiplexed/S2/*)

for i in {0..8}
	do
	echo $1
	echo ${S1[$i]}
	echo ${S2[$i]}
	f1=${S1[$i]}
	f2=${S2[$i]}
	name1=${f1##*/}
	name2=${f2##*/}
	echo $name1
	echo $name2
	cat "$f1" "$f2" > ../coastal.demultiplexed/SC/com."${name1}"
	gzip ../coastal.demultiplexed/SC/com."${name1}"
done
