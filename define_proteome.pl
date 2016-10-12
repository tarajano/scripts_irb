#!/usr/bin/env perl
#
# created on: 08/Mar/2011 by M.Alonso
#
#
# Defining Human proteome from uniprot 2010_09
#   Leaving out Fragments, cDNA and entries with PE>3.
#   Selecting representative AC per Human Cluster
#     Selection Criteria (by order of relevance):
#     1) Source: swissprot (score: 5), trembl (score: 1)
#     2) PE: 1(score: 3), 2 (score: 2), 3 (score: 1)
#
#
# This proteome has been created for using as a bground with the SLiMFinder package
#
#
#

use DBI;
use strict;
use warnings;

use lib "$ENV{HOME}/phd/kinome/scripts/modules";
use Retrieve_seq_by_AC_local;

my $human_uniref100="/aloy/data/dbs/uniprot/uniprot_2011_11/uniref-100.txt";
my $fastain="/aloy/data/dbs/uniprot/uniprot_2011_11/uniprot.fasta";
my $fastaout="hs_proteome_uniprot_2011_11.fasta";


my (%uniprot_human,%human_uniref100,%representative_acs);
my (@fields,@acs);

######
## Connecting to: uniprotkb
my $conn = DBI->connect("dbi:Pg:dbname=uniprotkb_2011_11;host=pac-node105;port=5432;user=uniprot_user;password='uniprot'");
######

######
## Retrieving/Loading Human entries from DB. 
## Leaving out Fragments, cDNA and entries with PE>3
##
## Note about (not) using the keyword: 'Complete proteome':
##   No uniprot entry with PE>3 is in the 'Complete proteome'
##   Only 14 uniprot2010_09 entries belonging to fragments are in the 'Complete proteome'
## 
print "Retrieving/Loading Human entries from DB\n";
my $query = $conn->prepare( "SELECT uniprot_ac,uniprot_id,fullname,existence,source FROM uniprotkb_protein ".
                            "WHERE taxid='9606' AND ".
                            "existence NOT LIKE '4:%' AND existence NOT LIKE '5%' AND ".
                            "flag NOT LIKE '%ragment%' AND fullname NOT LIKE 'cDNA%' ")or die $conn->errstr;
$query->execute() or die $conn->errstr;

while (my @row = $query->fetchrow_array()){
  $uniprot_human{$row[0]}=[@row[1..$#row]];
}
$query->finish();
######

######
## disconnecting DB
$conn->disconnect();
######


######
## Processing UniRef-100 file
print "Processing UniRef-100 file\n";
open(I,$human_uniref100) or die;
my $i=0;

while(<I>){
  chomp();
  @fields = split('\t',$_);
  $fields[2] =~ s/\s+//g;
  @acs = human_clusters($fields[2]);
  if(@acs>0){
    $human_uniref100{$i}=[@acs];
    $i++;
  }
}
close(I);
######

######
## Select and Store representative AC per Human Cluster
foreach my $k (keys %human_uniref100){
  @acs = representative_ac($human_uniref100{$k});
  if(@acs>1){$representative_acs{$acs[0]}=join(",",@acs[1..$#acs]);}
  else{$representative_acs{$acs[0]}="";}
}
#open(O,">humanproteome.acs");
#print O "$_\t$representative_acs{$_}\n" foreach(keys %representative_acs);
#close(O);
######

######
## Retrieving sequences.
## Using module Retrieve_seq_by_AC_local.pm
retrieve_sequences($fastain,$fastaout,\%representative_acs);
######


print("Finished\n");



######################
#### SUBROUTINES #####
######################

######################
## Identifying UniRef-100 clusters with human proteins
sub human_clusters{
  my @fields = split(";",$_[0]);
  my @acs; my $ac;
  
  foreach $ac (@fields){
    if(exists $uniprot_human{$ac}){
      push(@acs,$ac);
    }
  }
  return @acs;
}
######################


######################
## Select representative AC per Human Cluster
##
## Selection Criteria (by order of preference):
## 1) Source: swissprot (score: 5), trembl (score: 1)
## 2) PE: 1(score: 3), 2 (score: 2), 3 (score: 1)
##
## uniprot_human{ac}=uniprot_id,fullname,existence,source

sub representative_ac{
  my @acs = @{$_[0]};
  my $ac;
  my %acs_score;
  my @acs_sorted_by_score;
  
  ## Initilizing %acs_score hash
  $acs_score{$_}=0 foreach (@acs);
  
  ## Scoring 
  foreach $ac (@acs){
    # source
    if($uniprot_human{$ac}[3] eq "sprot"){
      $acs_score{$ac}+=5;
    }elsif($uniprot_human{$ac}[3] eq "trembl"){
      $acs_score{$ac}+=1;
    }
    
    if($uniprot_human{$ac}[2] eq "1: Evidence at protein level"){
      $acs_score{$ac}+=3;
    }elsif($uniprot_human{$ac}[2] eq "2: Evidence at transcript level"){
      $acs_score{$ac}+=2;
    }elsif($uniprot_human{$ac}[2] eq "3: Inferred from homology"){
      $acs_score{$ac}+=1;
    }
  }

  #foreach (sort {$acs_score{$b} <=> $acs_score{$a}} keys %acs_score){
    #print "$_:$acs_score{$_}\t";
  #} print "\n";
  
  @acs_sorted_by_score = sort {$acs_score{$b} <=> $acs_score{$a}} keys %acs_score;

  return @acs_sorted_by_score;
}
######################











