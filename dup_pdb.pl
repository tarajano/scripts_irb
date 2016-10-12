#!/usr/bin/env perl
#
# identifying entries in the bestmodels file sharing the same PDB 
#
use strict;
use warnings;

my %pdb_based_hash;

##
open(F,$ARGV[0])or die; # provide the bestmodels file
while(<F>){
  chomp;
  my @fields = split("\t",$_);
  push(@{$pdb_based_hash{$fields[1]}},$_) if (defined $fields[1]);
}
close(F);
##

##
foreach my $pdbid (sort keys %pdb_based_hash){
  if(@{$pdb_based_hash{$pdbid}}>1){
    print "$_\n" foreach(@{$pdb_based_hash{$pdbid}});
    #print "$pdbid\n";
  }
}
