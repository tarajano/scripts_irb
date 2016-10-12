#!/usr/bin/env perl
#
# With this script Im creating individual fasta files for each of the PP domains contained in our 139 hpp.
# The resulting files will be used for blasting vs the PDB and then to identify the best template/strcuture for each PP domain.
#
# input files:
#
# ./script.pl 139HPP.ac2pfamdom_v2, 139hpp.fasta
# 
# input file: 139HPP.ac2pfam_v2
#Q12974 PF00102 Y_phosphatase 6.4e-09 18  149
#Q9BV47 PF00782 DSPc  4.6e-31 69  204
#Q9ULR3 PF00481 PP2C  6.1e-12 223 324
#
#

use strict;
use warnings;

my (@a,@ac2pfam);
my %FastaSeqs; # {ac}=>sequence_in_one_line
my %ac_pfam; # storing file 139HPP.ac2pfam_v2
my ($outfile,$deflineid,$seqfrag,$ini,$end);

##
open(F,$ARGV[0]) or die; # fasta file 139hpp.fasta
@a=<F>; 
chomp(@a);
%FastaSeqs=fasta2hash(@a);
close(F);
##
##
open(F,$ARGV[1]) or die; # file 139HPP.ac2pfam_v2
@ac2pfam=<F>; 
chomp(@ac2pfam);
close(F);
##


########################
## 
## 
foreach my $ac (keys %FastaSeqs){
  foreach my $ac2pfam (@ac2pfam){
    my @fields = split("\t",$ac2pfam);
    if($fields[0] eq $ac){
      $outfile = $ac."_".$fields[1]."_".$fields[4]."-".$fields[5].".fasta";
      $deflineid = $ac."_".$fields[1]."_".$fields[4]."-".$fields[5];
      $ini=$fields[4]-1;
      $end=$fields[5]-1;
      $seqfrag = join("",@{$FastaSeqs{$ac}}[$ini .. $end]);
      ## witing to output fasta file
      open(F,">$outfile") or die ;
      print F ">$deflineid | Fragment of residues $fields[4] - $fields[5] that contains the PFAM Domain $fields[1] ($fields[2])\n";
      print F "$seqfrag\n";
      close(F);
    }
  }
}
########################


#foreach(keys %fastaseqs){
  #print "$_\n";
  #print "@{$fastaseqs{$_}}\n";
#}

########################
# Creating an array from the protein sequence and 
# generating a hash AC->Seq for every entry
sub fasta2hash{
  my @array = @_;
  my %hash; my $seq=""; my $key="";
  
  ##
  foreach my $line (@array){
    if($line =~ /^>\w{2}\|(\w+)/){ # taking the AC as key
      if($key eq ""){;}
      elsif($key ne ""){
        # Creating an array for every the protein sequence so that can be 
        # used later for serching the fragment corresponding to the Pfam domain
        $hash{$key}=[split("",$seq)];
        $seq="";
      }
      $key=$1; # AC is the hash key
    }elsif($line =~ /^[A-Za-z]/){
      $seq=$seq.$line;
    }
  }
  $hash{$key}=[split("",$seq)];
  ##
  return %hash;
}
#########################

