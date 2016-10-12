#!/usr/bin/env perl
#
# counting how meny 3D strs/templs per hpkd
#
# input
#AGC_AKT__AKT1_3cquA
#AGC_AKT__AKT1_3cqwA
#AGC_AKT__AKT1_3mv5A
#AGC_AKT__AKT1_3mvhA
#AGC_AKT__AKT2_1o6kA
#AGC_AKT__AKT2_1o6lA
#AGC_AKT__AKT2_2jdoA

use strict;
use warnings;
use List::MoreUtils qw(uniq);

my %hpkd_strs=();

open(I,$ARGV[0]) or die;
my @infile = <I>;
chomp(@infile);
close(I);
@infile = uniq(map(uc($_),@infile));

#printf("hpkds %d\n",scalar(@infile));

foreach(@infile){
  chomp;
  my @fields = split("_",$_);
  my $hpkd = join("_",@fields[0..3]); # GRP_FAM_SUBFAM_HPKD
  
  if(exists $hpkd_strs{$hpkd}){
    $hpkd_strs{$hpkd}++;
  }else{
    $hpkd_strs{$hpkd}=1;
  }
}

#printf("hpkds %d\n",scalar(keys %hpkd_strs));

foreach(sort {$a cmp $b} keys %hpkd_strs){
  print "$_\t$hpkd_strs{$_}\n";
}





















