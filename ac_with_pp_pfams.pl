#!/usr/bin/env perl
#
# Parsing scanpfam output to get the acs with PP Pfam domains.
#
# input:
# pfamscan output files
#
# output:
# 
#
#
#

use strict;
use warnings;

### PFAM Domains of Protein Phosphatases
my %ppPfam=(
'PF06602' => 'Myotub-related',
'PF10409' => 'PTEN_C2',
'PF00102' => 'Y_phosphatase',
'PF00149' => 'Metallophos',  
'PF00481' => 'PP2C',    
'PF00782' => 'DSPc',           
'PF01451' => 'LMWPc',           
'PF03031' => 'NIF',          
'PF04722' => 'Ssu72',
'PF06617' => 'M-inducer_phosp',
'PF07228' => 'SpoIIE',
'PF07830' => 'PP2C_C',
'PF08321' => 'PPP5',
'PF12453' => 'PTP_N');


##### loading the scanpfam output files
#my @phosscanpfam=</aloy/scratch/malonso/pphosphatase/ec_txt_hugo/fastas/*pfamscan.out>; # path to scanpfam output files
my @phosscanpfam=</aloy/scratch/malonso/pphosphatase/phbase/fastas/*pfamscan.out>; # path to scanpfam output files

#merged pfamscan from ec-txt-hugo + phbase
#my @phosscanpfam=</aloy/scratch/malonso/pphosphatase/139HPP_folder/pfamscam_EC_PhBase_merged/fastas/*pfamscan.out>; # path to scanpfam output files

my %PhosPfam=(); # this hash contain the assigned PFAM domains for each phosphatase
my %no_PPDomain=();
my %yes_PPDomain=();

foreach my $file (@phosscanpfam){
  my $key; my @fields=(); my @pfamids=();
  ## taking %PhosPfam keys (AC) from each path/filename
  $file =~ /(\w+)\.fasta\.pfamscan\.out$/;
  $key = $1;
  if(-s $file){ # if file is not empty
    open(F,$file) or die;
    my $repeated_dom=0;
    while(<F>){
      chomp;
      #fields: sp|A4D256|CC14C_HUMAN DSPc  3.2e-15 ? 316 443 PF00782.13
      @fields = split ("\t",$_);
      my ($pfamdom,$tmp)=split('\.',$fields[6]);
      
      ## handling repeated domains in a protein sequence
      if(exists $PhosPfam{$key}{$pfamdom}){
        $repeated_dom++;
        $pfamdom = $pfamdom."-".$repeated_dom;
      }
      ## filling the AC-DOMAIN hash
      push(@{$PhosPfam{$key}{$pfamdom}},[$fields[1],$fields[2],$fields[4],$fields[5]]);
      
      ### Identifying the proteins without PP Pfam domains and storing them in %no_PPDomain
      if($pfamdom !~ /-/ && exists $ppPfam{$pfamdom}){
        $yes_PPDomain{$key}=1;
      }else{
        $no_PPDomain{$key}=1;
      }
      ## if a protein has a PP Pfam domain, then delete it from %no_PPDomain
      foreach (keys %no_PPDomain){
        delete $no_PPDomain{$key} if(exists $yes_PPDomain{$_});
      }
      ###
    }
    close(F);
  }else{
    $PhosPfam{$key}{'-'}=[];
    $no_PPDomain{$key}=1;
  }
##print "$_ @{$PhosPfam{$_}}\n" foreach (sort keys %PhosPfam);
}
#print ".... done loading the scanpfam output files\n";
#####

############
## printing all the results from Pfam Scan
#foreach my $k1 (keys %PhosPfam){
  #foreach my $k2 (keys %{$PhosPfam{$k1}}){
    #print "$k1\n" if($k2 eq "-");
    #foreach (@{$PhosPfam{$k1}{$k2}}){
      #print "$k1\t$k2\t";
      #printf("%s\n",join("\t",@{$_}));
    #}
  #}
#}
############

############
## printing the data from proteins with PP Domains from Pfam Scan
foreach my $k1 (keys %yes_PPDomain){
  foreach my $k2 (keys %{$PhosPfam{$k1}}){
    print "$k1\n" if($k2 eq "-");
    foreach (@{$PhosPfam{$k1}{$k2}}){
      print "$k1\t$k2\t";
      printf("%s\n",join("\t",@{$_}));
    }
  }
}
############
############
## printing the proteins with PP Pfam domains
#foreach (keys %yes_PPDomain){
  #print "$_\n";
#}
############
############
## printing the proteins witout PP Pfam domains
#foreach (keys %no_PPDomain){
  #print "$_\n";
#}
############

