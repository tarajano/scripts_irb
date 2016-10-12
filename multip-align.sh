#!/bin/bash
# creating multiple seuence align and trees
# ./script sequneces.fasta
clustalw -infile=$1 -align -quiet -type=PROTEIN -outfile=$1.aln
clustalw -infile=$1.aln -tree -clustering=nj -bootstrap=10000 -quiet -outputtree=$1.ph
