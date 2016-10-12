#!/usr/bin/env perl
#
#
#
use strict;
use warnings;

my %pdb_org;
my @fields;

open(PDBENT,$ARGV[0]) or die; # provide PDB entries.idx file
while(<PDBENT>){
  @fields=split("\t",$_);
  $pdb_org{lc($fields[0])}=$fields[4];
}
close(PDBENT);


# AGC     AKT     -       -       AKT3    3DHOM   3cqw_A
open(F,$ARGV[1]) or die; # provide best models file file (e.g. ePK_mapped_best_models_v3.cvs)
while(<F>){
  chomp;
  @fields=split("\t",$_);
  if($fields[6] ne "-"){
    my ($pdb,$chain) = split("_",$fields[6]);
    print $_;
    print "\t$pdb_org{$pdb}\n";
  }else{
    print $_;
    print "\t-\n";
  }
  
}
close();
