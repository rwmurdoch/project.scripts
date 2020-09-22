#!/bin/bash

# a very simple script for chopping the head and tail off of the prokka gff file
# must be adjusted if you modify your scaffold names such that they don't begin with "gnl"

grep -v "^#" WPTOB.gff | less -S | grep "gnl" | grep -v ">" > WPTOB.gff3like
