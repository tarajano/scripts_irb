#!/usr/bin/env perl
#
# getting the intersection of two fasta files
# 
#
#

use strict;
use warnings;

my (@Query,@Subj);
my (%QuerySeqs,%SubjSeqs);

##
open(F,$ARGV[0]) or die; # fasta
@Query=<F>; 
chomp(@Query);
%QuerySeqs=fasta2hash(@Query);

open(F,$ARGV[1]) or die; # fasta
@Subj=<F>; 
chomp(@Subj);
%SubjSeqs=fasta2hash(@Subj);
##

#########################
my $flag;
my ($q,$s);
foreach $q (keys %QuerySeqs){
  $flag=0;
  
  foreach $s (keys %SubjSeqs){
    if($QuerySeqs{$q} eq $SubjSeqs{$s}){
      $flag++;
      print "INTER $q -> $s\n";
    }
  }
  
  if($flag==0){
    print "DIFF $q\n";
    ##print "$QuerySeqs{$q}\n";
  }
  
}
#########################


########################
# Creating a single string from the fasta sequence and 
# creating a hash AC->Seq for every entry
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
