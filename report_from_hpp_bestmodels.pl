#!/usr/bin/env perl
#
# Generating a summary of 3D strcutures available per PFAM domain and PP family.
# 
# input: bestmodels file of a HPP domains
# 


use strict;
use warnings;

# input file:
#O00743_PF00149_46-241
#O14522_PF00102_1224-1458
#O14522_PF00102_934-1164 2ooq_B  1       231     47      277     100.0   100.0   82.2    2e-137  1.8     X-RAY DIFFRACTION


my %hppdata=();
#
my %ppd_pfamdom=(
PTP => [qw(PF00102 PF06617 PF12453 PF04722 PF01451)],
DSP=>[qw(PF00782)],
PSTP=>[qw(PF00149 PF00481 PF07228 PF07830 PF08321 PF03031)],
LIPID=>[qw(PF10409 PF06602)]);
#
my %pfamdom_ppdom=(
PF00149=>"PSTP", PF00481=>"PSTP", PF07228=>"PSTP", PF07830=>"PSTP", PF08321=>"PSTP", PF03031=>"PSTP",
PF00102=>"PTP", PF06617=>"PTP", PF12453=>"PTP", PF04722=>"PTP", PF01451=>"PTP",
PF10409=>"LIPID", PF06602=>"LIPID",
PF00782=>"DSP");
#
my %count_ppdoms=(
PF00102=>0, PF06617=>0, PF12453=>0, PF04722=>0, PF01451=>0,
PF00149=>0, PF00481=>0, PF07228=>0, PF07830=>0, PF08321=>0, PF10409=>0,
PF06602=>0, PF00782=>0, PF03031=>0);
#
my %count_ppdoms_3D=(
PF00102=>0, PF06617=>0, PF12453=>0, PF04722=>0, PF01451=>0,
PF00149=>0, PF00481=>0, PF07228=>0, PF07830=>0, PF08321=>0,
PF10409=>0, PF06602=>0, PF00782=>0, PF03031=>0);
#
my %count_ppdoms_per_ppfam=(PTP =>0, DSP=>0, PSTP=>0, LIPID=>0);
my %count_ppdoms_3D_per_ppfam=(PTP =>0, DSP=>0, PSTP=>0, LIPID=>0);
#

##
open(F,$ARGV[0]) or die; # hpp bestmodels
while(<F>){
  chomp;
  my ($header,$pdb_chain) = split("\t",$_);
  my @fields = split("_",$header);
  #$fields[0] uniprotAC
  #$fields[1] pfamid
  #$fields[2] domIni-domEnd
  ## counting entries per PP domain
  $count_ppdoms{$fields[1]}++;

  if(defined $pdb_chain){
    $hppdata{$fields[0]}{$fields[1]}{$fields[2]}=$pdb_chain;
    ## counting 3D strs per PP domain type
    $count_ppdoms_3D{$fields[1]}++;
  }else{
    $hppdata{$fields[0]}{$fields[1]}{$fields[2]}="";
  }
}
close(F);
##

### counting ppdoms with 3D str per pp family 
#foreach my $ac (keys %hppdata){
  #foreach my $pfamid (keys %{$hppdata{$ac}}){
   #foreach my $iniendres (keys %{$hppdata{$ac}{$pfamid}}){
      #if($hppdata{$ac}{$pfamid}{$iniendres} ne ""){
        #$count_ppdoms_3D_per_ppfam{$pfamdom_ppdom{$pfamid}}++ if(exists $pfamdom_ppdom{$pfamid});
      #}else{
      #}
    #} 
  #}
#}
#print "$_ $count_ppdoms_3D_per_ppfam{$_}\n" foreach (keys %count_ppdoms_3D_per_ppfam);
###

## counting the number of ppdomains per pp family
foreach my $pfamid ( keys %count_ppdoms){
  $count_ppdoms_per_ppfam{$pfamdom_ppdom{$pfamid}} += $count_ppdoms{$pfamid};
}
#print "$_ $count_ppdoms_per_ppfam{$_}\n" foreach (sort keys %count_ppdoms_per_ppfam);
##

## counting the number of ppdomains with 3D per pp family
foreach my $pfamid ( keys %count_ppdoms_3D){
  $count_ppdoms_3D_per_ppfam{$pfamdom_ppdom{$pfamid}} += $count_ppdoms_3D{$pfamid};
}
#print "$_ $count_ppdoms_3D_per_ppfam{$_}\n" foreach (sort keys %count_ppdoms_3D_per_ppfam);

##
## entries per PP domain
#print "$_ $count_ppdoms{$_}\n" foreach (sort keys %count_ppdoms);
## 3D strs per PP domain type
#print "$_ $count_ppdoms_3D{$_}\n" foreach (sort {$count_ppdoms_3D{$b}<=>$count_ppdoms_3D{$a}} keys %count_ppdoms_3D);


foreach my $ppfam (sort keys %count_ppdoms_per_ppfam){
  print "$ppfam $count_ppdoms_3D_per_ppfam{$ppfam}"."/"."$count_ppdoms_per_ppfam{$ppfam}\n";
  foreach my $pfamdom (sort @{$ppd_pfamdom{$ppfam}}){
    print "\t$pfamdom $count_ppdoms_3D{$pfamdom}"."/"."$count_ppdoms{$pfamdom}\n";
  }
}




