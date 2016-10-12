#!/usr/bin/env perl
#
# re-orgabnizing the classification and name of hpkds in the hpkd.fasta 
#
use strict;
use warnings;

my %hpkds=();

#open(FASTA,"/home/malonso/phd/kinome/hpk/hpkd.fasta") or die;
open(FASTA,"/aloy/scratch/malonso/test/hpk_vs_pfam/hpkp.fasta") or die;

while(<FASTA>){
  chomp();
  if (/^>(.+)/){
    my ($name,$class) = split('\s+',$1);
    $class =~ s/\//_/g;
    $class =~ s/\(//g;
    $class =~ s/\)//g;
    print ">$class"."_".$name."\n";
  }else{
    print "$_\n";
  }
}
close(FASTA);
