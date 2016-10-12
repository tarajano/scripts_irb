#!/usr/bin/env perl
#
# created on: 11/Feb/2011 by M.Alonso
#
use strict;
use warnings;

#########################
open(I,$ARGV[0]) or die;
my @dali=<I>;
chomp(@dali);
close(I);
######
open(I,$ARGV[1]) or die;
my @rapido=<I>;
chomp(@rapido);
close(I);
######
my (%dali_rmsd,%rapido_flexrmsd);
my @fields;
foreach (@dali){
  @fields=split("\t",$_);
  $dali_rmsd{$fields[0]}{$fields[1]}=$fields[3];
}
foreach (@rapido){
  @fields=split("\t",$_);
  $rapido_flexrmsd{$fields[0]}{$fields[1]}=$fields[8];
}
#########################

#########################
foreach my $k1 (sort {$a cmp $b} keys %dali_rmsd){
  foreach my $k2 (sort {$a cmp $b} keys %{$dali_rmsd{$k1}}){
    printf("%s\n",join("\t",$k1,$k2,$dali_rmsd{$k1}{$k2},$rapido_flexrmsd{$k1}{$k2}));
  }
}
#########################







