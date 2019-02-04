#A simple script for turning a multifasta into a data frame which includes sequence lengths

library(Biostrings)


seq.table <- Biostrings::readDNAStringSet("your/path")

names <- names(seq.table)
seq <- paste(seq.table)
len <- width(seq.table)

seq.table <- data.frame(names, seq, len)
