#!/usr/bin/env perl
#
# Generating color codes for representation in HyperTree.
# 1) Taking each entry in a given fasta file (the source file for multp-alignment),
# 2) looking for its corresponding best model (if any) in a ScanPDB experiment
# 3) and generating a colorfile for presentation of the phylogenetic tree (seq-based) of aligned sequences
# 
# 4) color ranges (%QC>=99):
#   %SI>=99: red
#   %SI>=95: Green
#   %SI>=90: Blue
#
# A4D256_PF00782_316-443  1ohc_A  1 128 198 325 97.7  100.0 37.8  3e-72 2.5 X-RAY DIFFRACTION 

use strict;
use warnings;

open(I,$ARGV[0]) or die;
my @bestmodels=<I>;
close(I);

foreach my $dom(@bestmodels){
  my @fields = split("\t",$dom);
  if(defined $fields[1]){ # if theres a model ... 
    if($fields[6]==100){ # if %SI is..
      print "$fields[0]=0,250,0\n"; # green
    }elsif($fields[6]<100 && $fields[6]>=99){
      print "$fields[0]=0,0,250\n"; # blue
    }elsif($fields[6]<99 && $fields[6]>=98){
      print "$fields[0]=139,69,19\n"; # chocolate
    }elsif($fields[6]<98 && $fields[6]>=95){
      print "$fields[0]=250,0,0\n"; # red
    }
  }
}



