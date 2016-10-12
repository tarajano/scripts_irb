#!/usr/bin/env perl
#
# Created by MAlonso on 2010-11-12
# Modified on 2010-03-18
#
#
# mapping ACs using the file "sprot_trembl_parsed_lines"
#
# INPUT:
#  list of ACs (note that sprot_trembl_parsed_lines do not contain isoforms)
# OUTPUT:
#  files with mapped & unmapped acs
#
# NOTE: 
# isoforms notations will be removed and only canonical ACs will be mapped
#
#

use strict;
use warnings;

my ($unipid,$unipac);

my @fields;
my @secACs;

my %ACtomap=();  # {AC}=1
my %ACmapped=(); # {AC}=[primAC,ID]

## set the sprot_trembl_parsed_lines file you want to use as mapping
my $referencefile = "/aloy/data/dbs/uniprot/uniprot_2010_09/sprot_trembl_parsed_lines_HUMAN";

###############
## load ACs to be mapped
open(F,$ARGV[0]) or die; # list of ACs to map
while(<F>){
  chomp;
  
  ## isoform2canonical
  @fields = split("",$_);
  $unipac = join("",@fields[0..5]);
  
  $ACtomap{$unipac}=1;
}
my $acs=keys %ACtomap;
print "... $acs ACs to map loaded\n";
close(F);
###############

###############
## Loading sprot_trembl_parsed_lines  & Performing mapping
## 002R_IIV3|Q197F8|Q197F8|458|RecName: Full=Uncharacterized protein 002R

print "Performing mapping. This might take long\n";

open(F,$referencefile) or die;
while(<F>){
  
  ## finish if all ACs were already mapped
  last if(0 == (keys %ACtomap));

  @fields=split('\|',$_);
  @secACs=split(";",$fields[2]);
  
  $unipid=$fields[0];
  $unipac=$fields[1];
  
  ## iterating trough the list of secondary acs
  foreach my $secAC (@secACs){
    ## if the current secAC exists in our mapping list
    if(exists $ACtomap{$secAC}){
      $ACmapped{$secAC}=[$unipac,$unipid];
      delete $ACtomap{$secAC};
    }
  }
}
close(F);
###############


###############
## Printing mapping results

print "Printing mapping results\n";

## Dealing with unmapped ACs (if any)
if(0 == (keys %ACtomap)){
  print "All query ACs were mapped\n";
}else{
  my $unmapped = keys %ACtomap;
  print "Unmapped ACs: $unmapped. (see file queryACs.unmapped)\n";
  open(U,">queryACs.unmapped") or die;
  print U "$_\n" foreach(keys %ACtomap);
  close(U);
}

## Dealing with mapped ACs (if any)
if(0 == (keys %ACmapped)){
  print "None query AC was mapped!\n";
}else{
  open(M,">queryACs.mapped") or die;
  print M "#old\tnewAC\tnewID\n";
  printf M ("%s\n",join("\t",$_,@{$ACmapped{$_}})) foreach( sort {$a cmp $b} keys %ACmapped);
  close(M);
}
###############





