#!/usr/bin/env perl
#
# created on: 23/Mar/2011 by M.Alonso
#
#
# Metric = AVG(STY-MatchingMotifs)*(STY-MatchingMotifs/ComparedMotifs)
#
#
#
#
#
use LoadFile;
use strict;
use warnings;


my @tdtfiles;
my ($avgscore,$STYmatchingSLIMS,$TotalComparisons,$pkpair,$distance);

###################
## Loading list of comparimotif compare.tdt files
## /.../comparimotifs_runs/00277-00496/00277-00496.compare.tdt
print "Loading list of comparimotif compare.tdt files\n";
@tdtfiles=File2Array("/aloy/scratch/malonso/working_on_phosphoDBs/integrateddbs/comparimotif.tdt.list");
###################



###################
print "Parsing, computing and printing\n";
open(O,">comparimotif.metric_distance.tab") or die;
#print O "pkpair\tTotalComp\tSTYmatchingSLIMS\tAVGscore\tmetric=AVG(Score)*(STYmatchingSLIMS/TotComp)\n";
foreach(@tdtfiles){
  my $file=$_;
  ($avgscore,$STYmatchingSLIMS)=avg_comparimotif_score($file);
  
  ########
  ## pkpair TotalComp STYmatchingSLIMS AVGscore metric=AVG(Score)*(STYmatchingSLIMS/TotComp)
  #$TotalComparisons=get_total_comparisons_made($file);
  ########
  ##($pkpair,$distance)=pk_pair_sim_metric_1($file,$avgscore,$STYmatchingSLIMS,$TotalComparisons);
  ##printf O ("%s\t",join("\t",$pkpair,$TotalComparisons,$STYmatchingSLIMS));
  ##printf O ("%2.3f\t%2.5f\n",$avgscore,$distance);
  ########
    
  ########
  ## pkpair STYmatchingSLIMS AVGscore distance=1/AVG(Score)*(STYmatchingSLIMS)
  ($pkpair,$distance)=pk_pair_distance_metric_3($file,$avgscore,$STYmatchingSLIMS);
  printf O ("%s\t",join("\t",$pkpair,$STYmatchingSLIMS));
  printf O ("%2.5f\t%2.5f\n",$avgscore,$distance);
  ########

}
close(O);
###################



###################
### SUBROUTINES ###
###################

########################
## Parsing CompariMotif logs file
## /aloy/scratch/malonso/working_on_phosphoDBs/hprd_v9/slimfinder_hprd9/comparimotifs_runs/00277-00496/00277-00496.compare.tdt
sub get_total_comparisons_made{
  my $file = $_[0];
  my @fields;
  my $TotalComparisons=0;
  
  ### Moving to the directory if the current pkpair
  ### for reading the corresponding comparimotif.log file
  my $cwd = `dirname $file`;
  chomp($cwd);
  chdir($cwd);
  
  open(L,"comparimotif.log") or die;
  while(<L>){
    chomp();
    if(/^#COMP/){
      /Comparing MotifFile & SearchDB:\s+(\S+)\s+comparisons/;
      $TotalComparisons=$1;
      $TotalComparisons =~ s/,//;
      last;
    }
  }
  #print "$cwd $TotalComparisons\n";
  close(L);
  return($TotalComparisons);
}
########################

###################
## Calculating the avg Score for those matching motifs containing at least one STY residue
sub avg_comparimotif_score{
  my $file = $_[0];
  my @fields;
  my $pair="";
  my ($STYmatchingSLIMS,$sumscore,$avgscore)=0;
  
  #@fields=split("/",$file);
  #$pair=$fields[-2];
  
  open(IN,$file)or die;
  while(<IN>){
    chomp;
    @fields=split('\t',$_);
    if($fields[12] ne "Score" && $fields[12] ne ""){
      ## The Score field
      if($fields[8] =~ /[sty]/i){
        ## Avg only the matched motifs containing S,T or Y
        $STYmatchingSLIMS++;
        $sumscore+=$fields[12];
      }
    }
  }
  close(IN);
  if($STYmatchingSLIMS>0){
    $avgscore=$sumscore/$STYmatchingSLIMS;
  }else{
    $avgscore=0;
  }
  #print "$avgscore $STYmatchingSLIMS ";
  return($avgscore,$STYmatchingSLIMS);
}
###################

###################
## Calculating the Summation Score for those matching motifs containing at least one STY residue
sub summation_comparimotif_score{
  my $file = $_[0];
  my @fields;
  my $pair="";
  my ($STYmatchingSLIMS,$sumscore,$avgscore)=0;
  
  #@fields=split("/",$file);
  #$pair=$fields[-2];
  
  open(IN,$file)or die;
  while(<IN>){
    chomp;
    @fields=split('\t',$_);
    if($fields[12] ne "Score" && $fields[12] ne ""){
      ## The Score field
      if($fields[8] =~ /[sty]/i){
        ## Avg only the matched motifs containing S,T or Y
        $STYmatchingSLIMS++;
        $sumscore+=$fields[12];
      }
    }
  }
  close(IN);
  if($STYmatchingSLIMS>0){
    $avgscore=$sumscore/$STYmatchingSLIMS;
  }else{
    $avgscore=0;
  }
  #print "$avgscore $STYmatchingSLIMS ";
  return($avgscore,$STYmatchingSLIMS);
}
###################



##################
#sub log10 {
#my $n = shift;
#return log($n)/log(10);
#}
###################

###################
## Simmilarity Metric for the PK pair is calculated as: 
## The Average Score for the STY-MatchingMotifs(*) multiplied by 
## the ratio between the number of STY-MatchingMotifs(*) and the Total Number of Compared Motifs
##
## (*) STY-MatchingMotifs between the PKs that contain at least one phospho acceptor residue: S,T,Y
##
## Formula of Simmilarity Metric = AVG(Score-STY-MatchingMotifs)*(STY-MatchingMotifs/TotalComparedMotifs)
##
sub pk_pair_sim_metric_1{
  my ($file,$avgscore,$STYmatchingSLIMS,$TotalComparisons) = ($_[0],$_[1],$_[2],$_[3]);
  my @fields;
  my $pkpair;
  my $metric=0;
  
  @fields=split("/",$file);
  $pkpair=$fields[-2];
    
  $metric=$avgscore*($STYmatchingSLIMS/$TotalComparisons);
  
  return($pkpair,$metric);
}
###################

###################
## Distance Metric for the PK pair is calculated as: 
## 1 divided by the Average Score for the STY-MatchingMotifs(*) multiplied by 
## the Log10 of the number of STY-MatchingMotifs(*).
##
## If STY-MatchingMotifs(*)==1, then I force Log10(STY-MatchingMotifs)==0.1 (!!!!)
##
## (*) STY-MatchingMotifs between the PKs that contain at least one phospho acceptor residue: S,T,Y
##
## Formula of Dissimilarity Metric = 1 / AVG(Score-STY-MatchingMotifs)*Log10(STY-MatchingMotifs)
##
sub pk_pair_distance_metric_2{
  my ($file,$avgscore,$STYmatchingSLIMS) = ($_[0],$_[1],$_[2]);
  my @fields;
  my $pkpair;
  my $metric=0;
  my $distance=0;
  
  @fields=split("/",$file);
  $pkpair=$fields[-2];
  
  if($STYmatchingSLIMS == 0){ 
    $distance=-1;   ## If STY-MatchingMotifs(*)==0, then distance == -1
  }elsif($STYmatchingSLIMS == 1){
    $distance=0.1;  ## If STY-MatchingMotifs(*)==1, then I force distance == 0.1
  }else{
    $metric=$avgscore*(log10($STYmatchingSLIMS));
    $distance=1/$metric;
  }
  
  return($pkpair,$distance);
}
###################

###################
## Distance Metric for the PK pair is calculated as: 
## Inverse of the Average Score for the STY-MatchingMotifs(*) multiplied by 
## the Log10 of the number of STY-MatchingMotifs(*).
##
## (*) STY-MatchingMotifs between the PKs that contain at least one phospho acceptor residue: S,T,Y
##
## Formula of Dissimilarity Metric = 1 / AVG(Score-STY-MatchingMotifs)*(STY-MatchingMotifs)
##
## NOTE: The calculation of the current metric does not need the use of the subroutine "get_total_comparisons_made"
## 
sub pk_pair_distance_metric_3{
  my ($file,$avgscore,$STYmatchingSLIMS) = ($_[0],$_[1],$_[2]);
  my @fields;
  my $pkpair;
  my $distance=0;
  
  @fields=split("/",$file);
  $pkpair=$fields[-2];
  
  if($STYmatchingSLIMS == 0){ 
    $distance=1;   ## If STY-MatchingMotifs(*)==0, then distance == -1
  }else{
    $distance=1/($avgscore*$STYmatchingSLIMS);
  }
  
  return($pkpair,$distance);
}
###################
