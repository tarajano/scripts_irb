#!/usr/bin/env perl
#
# created on: 28/Feb/2011 by M.Alonso
#
# Creating a table with PSites sequences reported for each PK in HPRDv9
#
#

use DBI;
use Cwd;
use strict;
use warnings;
use List::MoreUtils qw(uniq);


my (@hprd_id2ac,@hprd_isof_id2ac,%hprd_id2ac);
my %pevents; # {enzid}=[[site, residue, substrate_isoform_id],]
my %pevents_psiteseq; # {enzid}=[[site, residue, substrate_isoform_id,psiteseq],]

##################
## fetching P+events
my $conn = DBI->connect("dbi:Pg:dbname=hprd_ptm_db;host=localhost;port=5433;user=malonso;password='manuel'") or die;
## Fetch HPKs in hprd9 that are reponsible for a P+Event and that also has been mapped to Manning name
my $pevents = $conn->prepare( "SELECT enzyme_hprd_id, site, residue, substrate_isoform_id FROM hprd_ptm ".
                              "WHERE  enzyme_hprd_id!= '-' AND modification_type='Phosphorylation'")or die $conn->errstr;
                            #  "WHERE enzyme_hprd_id='XXXX' AND modification_type='Phosphorylation'")or die $conn->errstr;
$pevents->execute() or die $conn->errstr;
while(my @row = $pevents->fetchrow_array()){
  ## @row = [enzyme_hprd_id, site, residue, substrate_isoform_id]
  push(@hprd_id2ac,$row[0]);
  push(@hprd_isof_id2ac,$row[3]);
  push(@{$pevents{$row[0]}},[$row[1],$row[2],$row[3]]);
}
$pevents->finish;
##################

##################
## fetching P+events
my ($resnum,$resname,$subs_isof_id,$seq);
my ($psiteseq,$downstream,$upstream);
my @subs_seq;
####
## Number of residues to include in the psite
## at both sides of the phosphoaceptor aminoacid
my $vicinity=20;
####

my $getSubstSeq = $conn->prepare("SELECT prot_seqs FROM hprd_prot_seqs WHERE isoform_id=?")or die $conn->errstr;

foreach my $k1 (keys %pevents){
  foreach (@{$pevents{$k1}}){
    #($site,$residue,$subs_isof_id)=@{$_};
    my ($resnum,$resname,$subs_isof_id)=@$_;
    #print "@$_\n";
    $getSubstSeq->execute($subs_isof_id) or die $conn->errstr;
    while(my @row = $getSubstSeq->fetchrow_array()){
      ## working with substrate sequence
      @subs_seq = split("",$row[0]);
      if($subs_seq[($resnum-1) eq $resname]){
        $upstream=($resnum-1)-$vicinity;
        $downstream=($resnum-1)+$vicinity;
        $upstream=0 if($upstream<0); # avoing negative values (they go beyond first residue)
        $downstream=$#subs_seq if($downstream>$#subs_seq); # avoid going beyond the last residue
        $psiteseq=join("",@subs_seq[$upstream..$downstream]);
      }
    }
    push(@{$pevents_psiteseq{$k1}},[$resnum,$resname,$subs_isof_id,$psiteseq]);
  }
}
$getSubstSeq->finish;
##################

##################
## MAPPING HPRD_IDS TO ACs
@hprd_id2ac = uniq(@hprd_id2ac);
my $id2ac = $conn->prepare("SELECT swissprot_ac FROM hprd_id_mappings WHERE hprd_id=?")or die $conn->errstr;
foreach(@hprd_id2ac){
  $id2ac->execute($_) or die $conn->errstr;
  while(my @row = $id2ac->fetchrow_array()){
    $hprd_id2ac{$_}=$row[0];
  }
}
$id2ac->finish;

#########
### Mapping hprd isoforms ids to ACs

#@hprd_isof_id2ac = uniq(@hprd_isof_id2ac);
#my @row;
#my $refseq_map = $conn->prepare("SELECT swissprot_ac FROM hprd_id_mappings WHERE refseq_id IN (SELECT refseq_id FROM hprd_prot_seqs where isoform_id=?)")or die $conn->errstr;
#my $gene_symb_map = $conn->prepare("SELECT swissprot_ac FROM hprd_id_mappings WHERE genesymbol IN (SELECT distinct(substrate_gene_symbol) FROM hprd_ptm WHERE substrate_isoform_id=?)")or die $conn->errstr;
#foreach(@hprd_isof_id2ac){
  #$refseq_map->execute($_) or die $conn->errstr;
  #while(@row = $refseq_map->fetchrow_array()){
    #$hprd_id2ac{$_}=$row[0];
  #}
  #if (! defined $row[0]){
    #$gene_symb_map->execute($_) or die $conn->errstr;
    #while(@row = $gene_symb_map->fetchrow_array()){
      #$hprd_id2ac{$_}=$row[0];
    #}
  #}
#}
#$refseq_map->finish;
#$gene_symb_map->finish;
##########

##################

#################
## print out
my $dir = getcwd;
my $outfile = $dir."/"."hprd_psite_seq_per_PK.out";
my $outfilefasta = $dir."/"."hprd_psite_seq_per_PK.fasta";

open(O,">$outfile") or die;
foreach my $enzid (keys %pevents_psiteseq){
  foreach (@{$pevents_psiteseq{$enzid}}){
    #($site,$residue,$subs_isof_id)=@{$_};
    my ($resnum,$resname,$subs_isof_id,$seq)=@$_;
    printf O ("%s\n",join("\t",$enzid,$hprd_id2ac{$enzid},$resnum,$resname,$subs_isof_id,$seq));
    ## If for the output instead of having subs_isof_ids you want to have subs_isof_acs
    ##  1) comment the line above, 2) uncomment the next command line and 3) uncomment the section "Mapping hprd isoforms ids to ACs" in this script
    ##  NOTE THAT having ACs instead of subs_isof_ids will create the problem of ambigous headers given that proper isoform labeling is not taken into account when mapping subs_isof_ids to uniprot ACs
    #printf O ("%s\n",join("\t",$enzid,$hprd_id2ac{$enzid},$resnum,$resname,$hprd_id2ac{$subs_isof_id},$seq)); ## uncomment 
    
  }
}
close(O);
#################
# print fasta
open(O,">$outfilefasta") or die;
foreach my $enzid (keys %pevents_psiteseq){
  foreach (@{$pevents_psiteseq{$enzid}}){
    #($site,$residue,$subs_isof_id)=@{$_};
    my ($resnum,$resname,$subs_isof_id,$seq)=@$_;
    printf O (">%s\n%s\n",join("-",$enzid,$hprd_id2ac{$enzid},$resnum,$resname,$subs_isof_id),$seq);
    ## If for the output instead of having subs_isof_ids you want to have subs_isof_acs
    ##  1) comment the line above, 2) uncomment the next line and 3) uncomment the section "Mapping hprd isoforms ids to ACs" in this script
    ##  NOTE THAT having ACs instead of subs_isof_ids will create the problem of ambigous headers given that proper isoform labeling is not taken into account when mapping subs_isof_ids to uniprot ACs
    #printf O (">%s\n%s\n",join("-",$enzid,$hprd_id2ac{$enzid},$resnum,$resname,$hprd_id2ac{$subs_isof_id}),$seq); ## uncomment 
  }
}
close(O);
#################




##
$conn->disconnect();
##################


