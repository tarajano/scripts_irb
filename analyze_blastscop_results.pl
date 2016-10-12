#!/usr/bin/env perl
#
# Analyzing the resutls contained in the file obtained from 
# the script "./parseBlastOutput_mapScop.pl hppd_blast_scop_resultfiles.list"
# 
# The file used as input looks like:
# A0M8Q2_PF00481_86-337 d1a6qa2 A:2-296 d.219.1.1 75802 231 2.0e-20 30.15 129 5 252 98.41 25  283 87.80 248 259 272
# A1A441_PF00149_17-218 d1auia_ A:  d.159.1.3 42085 1103  1.0e-122  99.50 200 2 202 99.50 72  272 42.49 201 201 201
# A1A4X0_PF00782_130-256  d1d5ra2 A:14-187  c.45.1.1  32697 336 3.0e-33 50.43 85  2 116 90.55 33  147 66.09 115 115 115
# A2A3K4_PF00782_100-243  d1ohea2 A:199-380 c.45.1.1  87014 149 2.0e-11 31.97 59  8 129 84.72 51  154 57.14 122 104 122
# This file contains the 
# 
# 
# 
use strict;
use warnings;
use List::MoreUtils qw(uniq);

my @infile;
my %hppd_with_scopfoldfam=();
my %pfam_doms_per_scop_folds=();
my %scop_fold_names=();
my %scopfoldfams=();


###########################
## provide input file. as commented above.
open(I,$ARGV[0]) or die;
@infile =<I>; chomp(@infile);
close(I);
###########################

###########################
## provide file "dir.des.scop.txt_1.75"
# 110509  fa  c.108.1.16  - NLI interacting factor-like phosphatase
open(SCOP,"/aloy/home/malonso/SCOP175/dir.des.scop.txt_1.75") or die;
while(<SCOP>){
  chomp;
  my @fields=split("\t",$_);
  ## {c.108.1.16}="NLI interacting factor-like phosphatase"
  unless($_ =~ /^#/){
    $scop_fold_names{$fields[2]}=$fields[4] if($fields[1] eq "fa");
  }
  
}
close(SCOP);
###########################

###########################
## number of HPP domains with a known Scop Fold Family at SI >= 30 %
##
print "--- HPP domains with a known Scop Fold Family (SI>=30%) ---\n";
foreach (@infile){
  my @fields=split("\t",$_);
  if(defined $fields[3]){
    $hppd_with_scopfoldfam{$fields[0]}=0;
  }
}
my $hppd_with_scopfoldfam = keys %hppd_with_scopfoldfam;
print "HPPD with a known Scop Fold Family: $hppd_with_scopfoldfam\n";
###########################

###########################
## retrieving the different scop fold families in the file 
##
print "--- Scop Fold Families in the file ---\n";
foreach (@infile){
  my @fields=split("\t",$_);
  if(defined $fields[3] && $fields[3] =~/^\w\.\d+\./){
    $scopfoldfams{$fields[3]}=0;
  }
}
print "$_:\t$scop_fold_names{$_}\n" foreach(sort keys %scopfoldfams);
###########################

###########################
### retrieving the number of HPP domains per scop fold family
###
#print "--- HPP domains per scop fold family ---\n";

#foreach (@infile){
  #my @fields=split("\t",$_);
  #if(defined $fields[3] && $fields[3] =~/^\w\.\d+\./){
    #$scopfoldfams{$fields[3]}++;
  #}
#}
#print "$_\t$scopfoldfams{$_}\n" foreach(sort keys %scopfoldfams);
###########################


###########################
## Pfam domain families perl Scop Fold Family.
##
my $pfamdom;
print "--- Pfam domain families (and instances) per Scop Fold Family ---\n";
foreach (@infile){
  my @fields=split("\t",$_);
  if(defined $fields[3] && $fields[3] =~/^\w\.\d+\./){
    my @hppd_fields =split("_",$fields[0]); # splitting A2A3K4_PF00782_100-243
    ## Storing the PfamFamilies present in each ScopFold
    ## {scopfold}=(pfam1,pfam2,pfam3,pfam1)
    push(@{$pfam_doms_per_scop_folds{$fields[3]}},$hppd_fields[1]);
  }
}
## Eliminating Pfam domains redundancies in the ScopFold::PfamDomains relations
## {scopfold}=(pfam1,pfam2,pfam3,pfam1)
foreach (sort keys %pfam_doms_per_scop_folds){
  ##
  my %counts=();
  foreach $pfamdom (sort @{$pfam_doms_per_scop_folds{$_}}){
    $counts{$pfamdom}++;
  }
  print "$_:\t";
  foreach $pfamdom (sort keys %counts){
    print "$pfamdom ($counts{$pfamdom}) ";
  }
  print "\n";
  ##
  
  #@{$pfam_doms_per_scop_folds{$_}}=uniq(map(uc($_),@{$pfam_doms_per_scop_folds{$_}}));
}
## Printing out
#foreach (sort keys %pfam_doms_per_scop_folds){
  #print "$_: @{$pfam_doms_per_scop_folds{$_}}\n";
#}
###########################































