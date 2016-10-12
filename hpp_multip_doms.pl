#!/usr/bin/env perl
#
# identifying and printing out hpp with more than one domain 
# input file 167_pfam_fragments/167_names (e.g line: A2A3K4_PF00782_100-243)
#
#
# 
use strict;
use warnings;

##
open(F,$ARGV[0])or die; # input file 167_pfam_fragments/167_names
my @ac_pfamdom=<F>;
chomp(@ac_pfamdom);
close(F);
##

my $oldac="";
my $olddom="";
my $oldline="";
my %dompairs=();
my %ac_dom_count=();


foreach (@ac_pfamdom){
  my ($ac,$dom) = split("_",$_);
  if($oldac eq ""){
  }else{
    
    if(exists $ac_dom_count{$ac}){
      $ac_dom_count{$ac}++;
    }else{
      $ac_dom_count{$ac}=1;
    }
    
    if($ac eq $oldac){
      my $key1 = $dom."-".$olddom;
      my $key2 = $olddom."-".$dom;
      if(exists $dompairs{$key1}){
        $dompairs{$key1}++;
      }elsif(exists $dompairs{$key2}){
        $dompairs{$key2}++;
      }else{
        $dompairs{$key1}=1;
      }
    }
  }
  $oldac=$ac;
  $olddom=$dom;
  $oldline=$_;
}

# Domain Pairs occurrences
open(F,">167_dom_pair_occur.list") or die;
print F "DomainPairs\tOccurrences\n";
print F "$_\t$dompairs{$_}\n"foreach (sort keys %dompairs);
close(F); 
# Domain Count per HPP
open(F,">hpp_domcount.list") or die;
print F "AC\tDomains\n";
foreach (sort { $ac_dom_count{$b} cmp $ac_dom_count{$a} } keys %ac_dom_count){
  print F "$_\t$ac_dom_count{$_}\n";
};
close(F);











