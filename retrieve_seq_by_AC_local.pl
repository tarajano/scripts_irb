#!/usr/bin/env perl
#
# Retrieving ACs from a local Uniprot file
#
# Description:
#   Given a file with a list of Uniprot ACs, 
#   fetches the corresponding fasta sequences from a local uniprot
#   fasta file.
# 
# 
# Returns
#   - If only an AC is given, returns a fasta file with the corresponding sequence
#   - If a file with a list of ACs is given, returns a file with all fasta sequences
#     and a zipped file with the sequence for each independent AC.
#   - A file with the ACs for which no sequence was found.
#
# Usage:
#   ./thisscript  /path/to/fileofacs  /path/to/uniprotfile/with/sequences.fasta
#
#

use strict;
use warnings;

use UniprotTools;

##################
unless(defined $ARGV[0] && defined $ARGV[1] && -e $ARGV[0] && -e $ARGV[1]){
  print "  Usage:\n  ./thisscript  /path/to/fileofacs  /path/to/uniprotfile/with/sequences.fasta\n";
  print "Remember to set the correct Uniprot fasta source file\n";
  exit;
}

### $ARGV[0] : myACs.list
### $ARGV[1] : /aloy/home/malonso/phd_proj_dbs/uniprot/uniprot_2011_11/hs_proteome_uniprot_2011_11.fasta
### 
ac2fastaseq_local($ARGV[0],$ARGV[1]);
##################
