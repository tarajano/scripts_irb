#!/usr/bin/env perl
#
# Retrieving the descriptions for HGCN ids that didn't find a mapping to AC.
#
# input: 
# 1) the file retrieved from HUGO DB containing information for each HGCN ids ("hp_genes.txt")
# 2) the file with the HGCN ids that didn't find a mapping to UniProt ACs (hp_hgnc2ac_notmapped.txt)
#
# output:
# lines in "hp_genes.txt" corresponding to the unmapped HGCN ids.
#
# usage:
# ./unmapped_hgcb.pl hp_genes.txt hp_hgnc2ac_notmapped.txt
#

use strict;
use warnings;

my (%Query);
my @hgnc;


############
# Provide the file: "hp_genes.txt" 
# HGNC ID Approved Symbol Approved Gene Name  Chromosome  Accession ID  Previous Symbols  Aliases
open(F,$ARGV[0]) or die;
while(<F>){
  chomp;
  $Query{$1}=$2 if(/(^\d+)\s+(.+)/);
  
}
############


############
# Provide the list of unmapped HGCN ids contained in the file "hp_hgnc2ac_notmapped.txt"
# HGNC:38076
# HGNC:38077
open(F,$ARGV[1]) or die;
while(<F>){
  chomp;
  push(@hgnc,$1) if(/^HGNC:(\d+)/);
  
}
############


foreach(sort {$a <=> $b} @hgnc){
  print "$_\t-->\t$Query{$_}\n" if(exists $Query{$_});
}
