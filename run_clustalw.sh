#!/bin/bash
#
# ./script sequeces.fasta
#
echo 'Redirecting output to logfile'
echo "Aligning..."
clustalw -infile=$1 -align -tree -type=PROTEIN -outfile=$1.aln -seqnos=ON -outputtree=nj -stats=$1.stats > $1.log
