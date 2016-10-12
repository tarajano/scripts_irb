#!/usr/bin/env perl
#
# created on: 24/Jan/2012 at 18:36 by M.Alonso
#
# This script will identify the Pfam Clans represented
# among the set of substrates enriched for a kinase family.
#
# The Pfam-Domain to Pfam-Clan assignments will be taken from the file 
# Pfam-C provided in Pfam DB realeases. Full path to Pfam-C must be set.
# The functions
#  (i) PfamUtils::loading_pfamclans_data ## set full path to Pfam-C
#  (ii) PfamUtils::pfamdom2clan
# will load the data on pfam clans (i) and assign domains to clans (ii)
# for the list of input (target) domains provided by the user.
# 
# Input files:
# The script needs two input files:
# 
# (i) A file with the results of Pfam domains enriched for kinase families.
# This file can be created by the script 'enrichment_in_pkfams_subs.pl'
# 
# (ii) A file with a list of kinase families for which you want to 
# create the PfamDomain to PfamClan assignments. The kinase families
# in this list must be also present in the file (i).
# 
# Output file:
# The output file will contain the format:
# hpkfam  clanAC  clanID  DomainsInstances
# where DomainsInstances is the number of domains instances of the
# corresponding PfamClan. These PfamDomains are the one that have been
# found to be enriched among the interactors of the kinase family.
# 
# 

use strict;
use warnings;
use LoadFile;
use List::MoreUtils qw(uniq);
use PfamUtils; ## by MAAT

my $inputfile;

my @fields;

my %hpkfam_list;
my %hpkfam_clan_mapped;

my %pfamdom2clan; ## {pfamdomAC}=pfamclanAC
my %pfam_clan_data; ## {clanAC}=[clanID,clanDE,[membersPfamID]]
my %pfam_enrichment_data; ## {HPKfam}{PfamID}=DomainInstances

##############################
## Load Pfam enrichment results.
## HPKfam  interactors  PfamAC  PfamID  DomainInstances
$inputfile = "/aloy/scratch/malonso/hpk_ppidb_201111/pfam_enrichments/enrichment_in_pkfams/enrichment_in_pkfams_interactors.tab";
foreach(File2Array($inputfile,2)){
  @fields = splittab($_);
  ## {HPKfam}{PfamAC}=DomainInstances
  $pfam_enrichment_data{$fields[0]}{$fields[2]}=$fields[4];
}
##############################

##############################
## Loading list of families to be analyzed.
$inputfile = "/aloy/scratch/malonso/hpk_ppidb_201111/corr_shared_partners_vs_substrates_within_hpkfams/within_hpkfams_shared_partners_shared_substrates.coefs";
foreach(File2Array($inputfile,1)){
  @fields = splittab($_);
  ## {hpkfam}=1
  $hpkfam_list{$fields[0]}=1;
}
##############################

##############################
## Loading data on Pfam Clans
## {clanAC}=[clanID,clanDE,[membersPfamAC]]
%pfam_clan_data = %{loading_pfamclans_data("/aloy/data/dbs/pfam/Pfam-C")};

## {pfamdomAC}=pfamclanAC
%pfamdom2clan = %{pfamdom2clan(\%pfam_clan_data)};
##############################

##############################
## Mapping Pfam clans to HPKfams 
my ($fam, $pfamdom, $clan, $pfamdom_instances);
foreach $fam (keys %hpkfam_list){
  next unless (exists $pfam_enrichment_data{$fam});
  
  foreach $pfamdom (keys %{$pfam_enrichment_data{$fam}} ){
    $pfamdom_instances = $pfam_enrichment_data{$fam}{$pfamdom};
    
    if (exists $pfamdom2clan{$pfamdom}){$clan = $pfamdom2clan{$pfamdom};}
    else{$clan = "NoClan";}
    
    if(exists $hpkfam_clan_mapped{$fam}{$clan}){
      $hpkfam_clan_mapped{$fam}{$clan}+=$pfamdom_instances;
    }else{
      $hpkfam_clan_mapped{$fam}{$clan}=$pfamdom_instances;
    }
  }
}
##############################

##############################
my $clanID;

## DomainsInstances: Instances (Pfam domains) of the current Pfam clan
## that are found in interactors of current kinase family.
##
printf ("%s\n", jointab(qw(hpkfam clanAC clanID DomainsInstances)) );
foreach $fam (sort {$a cmp $b} keys %hpkfam_clan_mapped){
  foreach $clan (sort {$a cmp $b} keys %{$hpkfam_clan_mapped{$fam}} ){
    if (exists $pfam_clan_data{$clan}){
      $clanID = $pfam_clan_data{$clan}[0];
    }else{
      $clanID = "NoClan";
    }
    printf ("%s\n", jointab($fam, $clan, $clanID, $hpkfam_clan_mapped{$fam}{$clan}));
  }
}
##############################








