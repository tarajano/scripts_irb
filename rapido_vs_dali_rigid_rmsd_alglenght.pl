#!/usr/bin/env perl
#
# Reading alignment results from DALI & RAPIDO and printing out rigid_RMSD
# and AlLenght for each pairwise alignment.
#
# created on: 28/Jan/2011 by M.Alonso
#
#
#

use strict;
use warnings;

my (%dali_data,%rapido_data);
my @fields;

#############################
## Loading DALI & RAPIDO 547 pairwise str.alignments data

## str1 str2 Z-score rmsd lali nres %id
open(F,"/aloy/scratch/malonso/struct_alignments/daliLite/dali_data_547_pairwise.dat")or die;
my @dali=<F>;
chomp(@dali);
close(F);
foreach(@dali){
  @fields = split("\t",$_);
  $dali_data{$fields[0]}{$fields[1]}=[@fields[2 .. $#fields]]; ## [Z-score rmsd lali nres %id]
}

## str1 str2 rmsd num_aligned len1 len2 lo_lim hi_lim ... 
open(F,"/aloy/scratch/malonso/struct_alignments/rapido/rapido_data_547_pairwise.dat")or die;
my @rapido=<F>;
chomp(@rapido);
close(F);
foreach(@rapido){
  @fields = split("\t",$_);
  $rapido_data{$fields[0]}{$fields[1]}=[@fields[2 .. $#fields]]; ## [rmsd num_aligned len1 len2 lo_lim hi_lim ... ]
}
#############################

foreach my $k1 (keys %dali_data){
  foreach my $k2 (keys %{$dali_data{$k1}}){
    ## if (dali_rmsd > rapido_rmsd && dali_alres <= rapido_alres)
    if($dali_data{$k1}{$k2}[1] > $rapido_data{$k1}{$k2}[0] && $dali_data{$k1}{$k2}[2] <= $rapido_data{$k1}{$k2}[1]){
      ## str1 str2 rapido_rmsd dali_rmsd rapido_alglen dali_alglen
      print "$k1\t$k2\t$rapido_data{$k1}{$k2}[0]\t$dali_data{$k1}{$k2}[1]\t$rapido_data{$k1}{$k2}[1]\t$dali_data{$k1}{$k2}[2]\n";
    }
  }
}












