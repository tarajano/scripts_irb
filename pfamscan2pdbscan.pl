#!/usr/bin/env perl
#
#
#
use strict;
use warnings;

my %query_list;
my %subject_list;
my @fields;

open(F,$ARGV[0])or die; # yesPPPfam_yesPPGO_123.list_ac2pfam
while(<F>){
  chomp;
  @fields = split("\t",$_);
  $query_list{$fields[0]}=join("\t",@fields[1..$#fields]);
}
close(F);

open(F,$ARGV[1])or die; # 346scanPDB_bestmodels
while(<F>){
  chomp;
  @fields = split("\t",$_);
  $subject_list{$fields[0]}=join("\t",@fields[1..$#fields]);
}
close(F);

foreach(sort keys %query_list){
  if(exists $subject_list{$_}){
    print "$_\t$query_list{$_}\t$subject_list{$_}\n";
  }
  else{
    print "$_\t$query_list{$_}\n";
  }
}
