#!/usr/bin/env perl
#
# created on: 26/Jan/2011 by M.Alonso
#
# locating the dali runs that failed to compute an RMSD value
#
#
#


use strict;
use warnings;

######################
## File containing the paths to all summary files
my @summary_files;
open(F,"/aloy/scratch/malonso/struct_alignments/daliLite/paths_to_summaries.txt");
@summary_files=<F>;
chomp(@summary_files);
@summary_files = sort (@summary_files);
close(F);


## locating failed computations of RMSD
my $runs=0;
my $rmsd_comp_failed=0;
my @rmsd_comp_failed;

foreach (@summary_files){
  $runs++;
  my $line =`sed -n "3 p" $_`;
  chomp($line);
  if($line eq ""){
    $rmsd_comp_failed++;
    push(@rmsd_comp_failed,$_);
  }
}
######################

print "total runs: $runs\n";
print "rmsd_comp_failed: $rmsd_comp_failed\n";

open(O,">dali_rmsd_computation_failed.txt") or die;
print O "$_\n" for(@rmsd_comp_failed);
close(O);
