#!/usr/bin/env perl
#
#
# created by MAlonso on 2010-11-29
#
#
#
#
use strict;
use warnings;

##########################
## uniprot_2010_09 SwissProt entries 
my %sp_human_acs=();
open(I,"/aloy/home/malonso/phd_proj_dbs/uniprot_2010_09/uniprot_2010_09_sp/uniprot_sprot.fasta") or die;
while(<I>){
  if (/^>/ && /HUMAN/){
    my @fields = split('\|');
    $fields[2] =~ /(\w+_HUMAN)\s+/;
    my $uniprotID = $1;
    ## sp_human_acs{uniprotAC}=uniprotID
    $sp_human_acs{$fields[1]}=$uniprotID;
  }
}
close(I);
##########################


##########################
my %hpk2ac=();
open(I,$ARGV[0]) or die;
while(<I>){
  chomp;
  my @fields = split("\t");
  my $hpkname = $fields[0];
  if (defined $fields[1]){ # if there is a match hpkname-AC
    my $pk_ac = $fields[1];
    foreach my $sp_ac (keys %sp_human_acs){
      if($pk_ac =~ /$sp_ac/){
        $hpk2ac{$hpkname}="$sp_human_acs{$sp_ac}\t".$_;
        last;
      }
    }
  }else{
    $hpk2ac{$hpkname}="UNPID_HUMAN\t".$_;
  }
}
close(I);
##########################

print "$hpk2ac{$_}\n" foreach(sort keys %hpk2ac);
