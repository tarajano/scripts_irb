#!/usr/bin/env perl
#
# getting the intersection of two fasta files
# 
#
#

use strict;
use warnings;

my (@Fasta);
my (%FastaSeqs);

##
open(F,$ARGV[0]) or die; # fasta file
@Fasta=<F>; 
chomp(@Fasta);
%FastaSeqs=fasta2hash(@Fasta);

###
foreach (keys %FastaSeqs){
  />\w{2}\|(\w+)|/;
  my $outfile=$1.".fasta";
  open(F,">$outfile") or die;
  print F "$_\n$FastaSeqs{$_}\n";
  close(F);  
}
###



########################
# Creating a single string from the fasta sequence and 
# creating a hash key->Seq for every entry
sub fasta2hash{
  my @array = @_;
  my %hash; my $seq=""; my $key="";
  
  ##
  foreach my $line (@array){
    if($line =~ /^>/){
      if($key eq ""){;}
      elsif($key ne ""){
        $hash{$key}=$seq;
        $seq="";
      }
      $key=$line;
    }elsif($line =~ /^[A-Za-z]/){
      $seq=$seq.$line;
    }
  }
  $hash{$key}=$seq;
  ##
  return %hash;
}
#########################






