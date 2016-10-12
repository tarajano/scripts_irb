#!/usr/bin/env perl
#
# getting the source org of a pdb file
#
use strict;
use warnings;
use List::MoreUtils qw(uniq);

my @pdbids;
###########
## From a file with a list of PDB ids
open(F,$ARGV[0]) or die;
@pdbids = <F>;
chomp(@pdbids);
@pdbids = uniq(map(uc($_),@pdbids));
close(F);
###########

###########
## From a tab delimited
#open(F,$ARGV[0]) or die;
#while(<F>){
  #chomp;
  #my @fields=split("\t",$_);
  #if(defined $fields[1]){
    #my ($pdbid,$chain)=split("_",$fields[1]);
    #push(@pdbids,$pdbid);
  #}
#}
#close(F);
#@pdbids = uniq(map(uc($_),@pdbids));
#close(F);
###########


###########
open(F,"/aloy/data/dbs/pdbmirror/derived_data/index/entries.idx") or die; # file: /aloy/data/dbs/pdbmirror/derived_data/index/entries.idx

my %pdbid_org=();
while(<F>){
  my @fields=split("\t",$_);
  if(defined $fields[4] && $fields[4] ne ""){
    $pdbid_org{$fields[0]}=$fields[4];
  }else{
    $pdbid_org{$fields[0]}="-";
  }
}
close(F);
#print "$_\t$pdbid_org{$_}\n" foreach (sort keys %pdbid_org);
###########

###########
## printing to output file
my $outputfile = $ARGV[0].".pdbs_mapped";
open(O,">$outputfile") or die;
foreach(sort @pdbids){
  if(exists $pdbid_org{$_}){
    print O "$_\t$pdbid_org{$_}\n";
  }else{
    print O "$_\tNotIn PDB\n";
  }
}
close(O);
###########

###########
## creating summary file
my %orgPDBsummary=();
open(I,"$outputfile") or die;
while(<I>){
  chomp;
  my($pdb,$tmp) = split("\t",$_);
  my ($org,$tmp2) = split (";",$tmp);
  
  if(exists $orgPDBsummary{$org}){
    $orgPDBsummary{$org}++;
  }else{
    $orgPDBsummary{$org}=1;
  }
}
close(I);

my $summaryfile = $outputfile.".organism_dist_summary";
open(O, ">$summaryfile") or die;
foreach (sort {$orgPDBsummary{$b} <=> $orgPDBsummary{$a}} keys %orgPDBsummary){
  print O "$_\t$orgPDBsummary{$_}\n";
}
close(O);
###########






