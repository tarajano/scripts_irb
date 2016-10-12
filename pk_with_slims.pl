#!/usr/bin/env perl
#
# created on: 14/Mar/2011 by M.Alonso
#
# Retrieving the number of PKs for wich it was possible to obtain at least one 
# SLiM by SlimFinder
#
#
use strict;
use warnings;


my @fields;
my %pk_motifs=();
my ($line,$file,$pkname,$motifs);


########################
## Retrieving the PKs for which it was possible 
## to derive a SLimFinder Motif

my $cvs = `find /aloy/scratch/malonso/working_on_phosphoDBs/integrateddbs/slimfinder_runs -name '*.cvs' `;
my @cvs = split('\n',$cvs);

foreach (@cvs){
  $file = $_;
  
  ### grabbing PK name
  @fields = split("/",$file);
  $pkname = $fields[-2];
  
  ### grabbing 2nd line 
  $line = `sed -n '2p' $file`;
  chomp($line);
  @fields = split('\t',$line);
  
  if($fields[12] && $fields[12] ne "-"){
    $motifs = `wc -l $file`;
    chomp($motifs);
    $motifs--;
    #print "$fields[0]\t$motifs\n";
    $pk_motifs{$pkname}=$motifs;
  }else{
    $pk_motifs{$pkname}=0;
  }
}
########################

########################
### printing out
print "$_\t$pk_motifs{$_}\n" foreach(sort {$pk_motifs{$b} <=> $pk_motifs{$a}} keys %pk_motifs);
########################
