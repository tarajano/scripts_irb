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


my %pevents; # {enzid}=[[site, residue, substrate],[],[]]
my %pevents_psiteseq; # {enzid}=[[site, residue, substrate, psiteseq],[],[]]

##################
## fetching P+Events per PK
my $conn = DBI->connect("dbi:Pg:dbname=integrated_phosphodbs;host=localhost;port=5433;user=malonso;password='manuel'") or die;

my $pevents = $conn->prepare( "SELECT pk_ac,site,residue,subst_id FROM psites")or die $conn->errstr;
$pevents->execute() or die $conn->errstr;
while(my @row = $pevents->fetchrow_array()){
  ## @row = [pk_ac,site,residue,subst_id]
  push(@{$pevents{$row[0]}},[$row[1],$row[2],$row[3]]);
}
$pevents->finish;
##################

##################
## fetching P+Sites per PK
my ($resnum,$resname,$subst_id,$seq);
my ($psiteseq,$downstream,$upstream);
my @subs_seq;
####
## Number of residues to include in the psite
## at both sides of the phosphoaceptor aminoacid
my $vicinity=20;
####

my $getSubstSeq = $conn->prepare("SELECT subst_seq FROM subst_seqs WHERE subst_id=? LIMIT 1")or die $conn->errstr;

foreach my $k1 (keys %pevents){
  foreach (@{$pevents{$k1}}){
    #($site,$residue,$subst_id)=@{$_};
    my ($resnum,$resname,$subst_id)=@$_;
    #print "@$_\n";
    $getSubstSeq->execute($subst_id) or die $conn->errstr;
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
    push(@{$pevents_psiteseq{$k1}},[$resnum,$resname,$subst_id,$psiteseq]);
  }
}
$getSubstSeq->finish;
##################


##
$conn->disconnect();
##################

#################
## print out
my $dir = getcwd;
my $outfile = $dir."/"."integratedphosphodb_psite_seq_per_PK.out";
my $outfilefasta = $dir."/"."integratedphosphodb_psite_seq_per_PK.fasta";

open(O,">$outfile") or die;
foreach my $enzid (keys %pevents_psiteseq){
  foreach (@{$pevents_psiteseq{$enzid}}){
    #(site,residue,subst_id,psiteseq)=@{$_};
    my ($resnum,$resname,$subst_id,$seq)=@$_;
    printf O ("%s\n",join("\t",$enzid,$subst_id,$resnum,$resname,$seq));
  }
}
close(O);
#################
# print fasta
open(O,">$outfilefasta") or die;
foreach my $enzid (keys %pevents_psiteseq){
  foreach (@{$pevents_psiteseq{$enzid}}){
    #(site,residue,subst_id,psiteseq)=@{$_};
    my ($resnum,$resname,$subst_id,$seq)=@$_;
    printf O (">%s\n%s\n",join("@",$enzid,$subst_id,$resnum,$resname),$seq);
  }
}
close(O);
#################






