#!/usr/bin/env perl
#
# 26/Jan/2011
# 
# Creating the output files with the distribution of 
# data points* across the ranges of delta RMSD.
# *RAPIDO & DALI structural alignment solution pairs
# 
#
# INPUT 
# rapido_vs_dali_rigid_rmsd_all.dat
#
# OUTPUT 
#
# delta_rmsd_rapido_lt_dali.dat
# delta_rmsd_dali_lt_rapido.dat
#
# From the output files I generated bars plot with the distribution afore mentioned
#
#



use strict;
use warnings;

my @rapido_vs_dali_rigid_rmsd_all;
my @delta_rmsd_rapido_lt_dali;
my @delta_rmsd_dali_lt_rapido;
my @fields;

my $ranges=20;

######################
## loading data of all rmsd rapido-dali pairs 
open(F,"/aloy/scratch/malonso/struct_alignments/histograms/all_vs_all_strs/rapido_vs_dali_rigid_rmsd_all.dat") or die;
@rapido_vs_dali_rigid_rmsd_all=<F>;
chomp(@rapido_vs_dali_rigid_rmsd_all);
close(F);
######################

######################
## Loading the delta rmsds
open(R,">rmsd_rapido_lt_dali.dat") or die;
open(D,">rmsd_dali_lt_rapido.dat") or die;

# 
foreach (@rapido_vs_dali_rigid_rmsd_all){
  @fields = split("\t",$_);
  if( $fields[2] < $fields[3] && $fields[3] < 15){
    push(@delta_rmsd_rapido_lt_dali,($fields[3]-$fields[2]));
    print R "$_\n";
  }
  if( $fields[2] > $fields[3] && $fields[3] < 15){
    push(@delta_rmsd_dali_lt_rapido,($fields[2]-$fields[3]));
    print D "$_\n";
  }
}
close(R);
close(D);
######################

######################
delta_rmsd_distribution(\@delta_rmsd_rapido_lt_dali,"delta_rmsd_rapido_lt_dali.dat");
delta_rmsd_distribution(\@delta_rmsd_dali_lt_rapido,"delta_rmsd_dali_lt_rapido.dat");
######################

######################
# Creating the output files with the distribution of 
# data points* across the ranges of delta RMSD.
# *RAPIDO & DALI structural alignment solution pairs

sub delta_rmsd_distribution{
  
  my @delta_rmsds = @{$_[0]};
  my $outfilename = $_[1];
  
  my %delta_rmsd_dist_clustered=();
  
  @delta_rmsds = sort {$a <=> $b} @delta_rmsds;
  
  my $lower_delta=$delta_rmsds[0];
  my $higer_delta=$delta_rmsds[-1];
  
  my $top=0;
  my $bottom=$lower_delta;
  my $shift=((($higer_delta+0.05)-$lower_delta)/$ranges);
  
  #####
  for(my $i=1;$i<=$ranges;$i++){
  $top = ($lower_delta + ($shift*$i));
  my $cluster = $bottom."-".$top;

    foreach my $d_rmsd (@delta_rmsds){
      $delta_rmsd_dist_clustered{$cluster}++ if($bottom <= $d_rmsd && $d_rmsd < $top);
    }
  $bottom = (($lower_delta + ($shift*$i))+0.001);
  }
  open(O,">$outfilename") or die;
  print O "delta_rmsd_range\tnumber_of_pairs\tlog_of_number_of_pairs\n";
  printf O ("%s\n", join("\t",$_,$delta_rmsd_dist_clustered{$_},log($delta_rmsd_dist_clustered{$_}))) foreach (sort {$a cmp $b} keys %delta_rmsd_dist_clustered);
  close(O);
}
######################














