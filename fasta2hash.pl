#!/usr/bin/env perl
#
#
#
# sending a fasta file to a hash structure
#
#
#
#

use strict;
use warnings;

my (@Fasta,@fields);
my (%FastaSeqs);

##
open(F,$ARGV[0]) or die; # fasta file
@Fasta=<F>; 
chomp(@Fasta);
%FastaSeqs=fasta2hash(@Fasta);

###
## UNIPROT
## >sp|P31946|1433B_HUMAN||14-3-3 protein beta/alpha OS=Homo sapiens GN=YWHAB PE=1 SV=3
## NCBI
## >gi|4502023|ref|NP_001617.1| RAC-beta serine/threonine-protein kinase [Homo sapiens]

foreach my $k (keys %FastaSeqs){
  @fields = split('\|',$k);
  ## UNIPROT
  printf("%s\n",join("\t",$fields[1],$fields[2],$FastaSeqs{$k}));
  ## NCBI
  #printf("%s\n",join("\t",$fields[3],$FastaSeqs{$k}));
  
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
    }else{;}
  }
  $hash{$key}=$seq;
  ##
  return %hash;
}
#########################






