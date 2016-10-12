#!/usr/bin/env perl
#
# adding the full classification (Group, Family, Subfamily, ProtName) to the bestsmodels file of HPKdomains vs PDB_fasta
#
# ./hpk_mapp_name2famsubfam.pl bestmodelsfile.tab
#
#
# example input:
#AKT1  3cqu_A  1 259 7 265 99.6  100.0 81.2  3e-152  2.2 X-RAY DIFFRACTION
#AKT2  3e88_A  1 258 7 264 99.6  100.0 80.4  7e-152  2.5 X-RAY DIFFRACTION
#AKT3
#CRIK

use strict;
use warnings;

## loading file with the classification of hpks 
## Group Family Subfamily ProtName
open(F,"/aloy/scratch/malonso/hpk/hpkdoms/531_hpks_class_fam_subfam_protname.tab") or die;
my @hpkclassif = <F>;
chomp(@hpkclassif);
close(F);

## loading the bestmodels file for hpk domains vs PDB 
my %bestresults=();
my @fields;
open(F,$ARGV[0]) or die;
while(<F>){
  chomp;
  @fields=split("\t",$_);
  $bestresults{$fields[0]}=join("\t",@fields[1 .. $#fields]);
}
close(F);
#print "$_\t$bestresults{$_}\n" foreach(keys %bestresults);

## mapping prot names from best results to class-fam-subfam from classification file 
foreach my $hpkname (keys %bestresults){
  foreach my $classif (@hpkclassif){
    @fields = split("_",$classif);
    if($fields[3] eq $hpkname){
      print "$fields[0]\t$fields[1]\t$fields[2]\t$hpkname\t$bestresults{$hpkname}\n";
      last;
    }
  }
}
foreach my $classif (@hpkclassif){
  @fields = split("_",$classif);
  print "$fields[0]\t$fields[1]\t$fields[2]\t$fields[3]\n" if(!exists $bestresults{$fields[3]});
}






