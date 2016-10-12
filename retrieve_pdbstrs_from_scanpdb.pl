#!/usr/bin/env perl
#
## Due to the merging of the solutions from Blast and SSEARCH programs
## the output file of ScanPDB script contains duplicated strs/templates (same PDB, same chain)
## for a given target sequence. (see example below)
##
## With this script I'm choosing a single str/template (PDB_chain) for each query sequence
##
# ABL1 252 1fpu  A 275 251 252 252 1 252 18  269 99.6  100.0 91.6  6e-150
# ABL1 252 1fpu  A 275 251 252 252 1 252 18  269 99.6  100.0 91.6  2e-124
# ABL1 252 1fpu  B 270 246 252 247 1 252 18  264 97.6  100.0 91.5  6e-145
# ABL1 252 1fpu  B 270 246 252 247 1 252 18  264 97.6  100.0 91.5  3e-120
# ABL1 252 1iep  A 274 251 252 252 1 252 18  269 99.6  100.0 92.0  6e-150
# ABL1 252 1iep  A 274 251 252 252 1 252 18  269 99.6  100.0 92.0  2e-124
#
# usage:
# ./script scanpd.out.merged
#
#

use strict;
use warnings;

my (@infile,@fields,@prev_fields,@non_indentical_pdbchains,@non_indentical_pdbs);
my $flag=0;

##############
## read in scanpdb output file
open(I,$ARGV[0]) or die;
@infile=<I>;
chomp(@infile);
close(I);
##############

##############
## Eliminating identical PDB_chain solutions (comming from blast & ssearch) for a given query
foreach my $line (@infile){
  @fields = split("\t",$line);
  
  if($flag>0){ # do nothing on first line
    if ($fields[0] eq $prev_fields[0] && $fields[2] eq $prev_fields[2] && $fields[3] eq $prev_fields[3]){ # store unless Query, PDB and PDBchain are the same of the previous record..
      push(@non_indentical_pdbchains, join("\t",@prev_fields));
    }
  }else{$flag++;}
  @prev_fields=@fields;
}
##############

##############
## 
$flag=0;
my %tmphash=();

foreach my $line (@non_indentical_pdbchains){
  @fields = split("\t",$line);
  
  if($flag>0){ # do nothing on first line
    
    if($fields[0] eq $prev_fields[0] && $fields[2] eq $prev_fields[2]){ # if Query and PDB are the same of the previous record..
      $tmphash{$fields[15]}=$line; # storing in a hash of key e-value
      $tmphash{$prev_fields[15]}=join("\t",@prev_fields); # storing in a hash of key e-value
    }else{
      ## process the %tmphash{e-value}
      my @keys = sort keys %tmphash;
      push(@non_indentical_pdbs, $tmphash{$keys[0]});
    }
  }else{$flag++;}
  @prev_fields=@fields;
}
##############

##############
#foreach(@non_indentical_pdbs){
  ##printf("%s\n",join("\t",@{$_}));
  #print "$_\n";
#}
##############












