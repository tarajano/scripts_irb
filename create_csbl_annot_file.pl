#!/usr/bin/env perl
#
# created on: 05/Jul/2012 at 17:47 by M.Alonso
#
#
# Generating a GO annotation file in the format required by the R package csbl.go
#
#

use strict;
use warnings;

use LoadFile;

my @fields;

my %hs_go_annot_data;

##############################
## 
my $AC2GO_mappings_file="/aloy/scratch/malonso/scaffolds/ptck_q_0905/scheme3/validation_of_potential_AS/hs_GOannot_proteome/humanproteome.ac2go";
foreach(File2Array($AC2GO_mappings_file)){
  @fields=splittab($_);
  if($fields[1] eq "NO_GO_TERMS_AVAIL"){
    push(@{$hs_go_annot_data{$fields[0]}},"")
  }else{
    push(@{$hs_go_annot_data{$fields[0]}}, $fields[2]);
  }
}
open(O, ">/aloy/scratch/malonso/scaffolds/ptck_q_0905/scheme3/validation_of_potential_AS/hs_GOannot_proteome/$0.csbl.go.annot") or die;
foreach my $ac (sort {$a cmp $b} keys %hs_go_annot_data){
  printf O ("%s %s\n", $ac, join(" ", @{$hs_go_annot_data{$ac}}));
}
close(O);
##############################
