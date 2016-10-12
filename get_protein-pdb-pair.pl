#!/usr/bin/env perl
#
#
#
use strict;
use warnings;

my %entries;
##
#A6NN98_PF06602_162-279 118 1lw3  A 513 118 118 118 1 118 161 278 100.0 100.0 23.0  5e-66
#A6NN98_PF06602_162-279 118 1lw3  A 513 118 118 118 1 118 161 278 100.0 100.0 23.0  2e-53
#A6NN98_PF06602_162-279 118 1m7r  A 513 118 118 118 1 118 161 278 100.0 100.0 23.0  5e-6
##

open(F,$ARGV[0])or die; # provide the scanpdb out file
my $prev_entry="";
my $prev_pdb="";

while(<F>){
  my @fields = split("\t",$_);
  # && $fields[2] eq $prev_pdb){
    
  if($fields[0] eq $prev_entry && $fields[2] eq $prev_pdb && $prev_entry ne ""){
    ;
  }else{
    print $_;
  }
  
  $prev_entry=$fields[0];
  $prev_pdb=$fields[2];
  
}
close(F);
##
