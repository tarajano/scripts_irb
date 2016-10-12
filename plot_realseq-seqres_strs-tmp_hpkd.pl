#!/usr/bin/env perl
#
# Nov 2010
# Script for plotting the distribution of strs/templates per HPKDs across 
# nine groups of PKs. Using the results from the RealSeq and SeqRes blast vs PDB
# 
# The histogram obtained from this script can be used instead of the one that contains only
# the data from blast of hpkds vs RealSeq
#
# usage:
# ./script
# need to set the proper paths to the gnuplot_template file
#

use strict;
use warnings;
use DBI;

my %hpkd_strs_tmpl =(); # {hpkd}=(strs,tmpls,strs+templates)

###################
## connecting DB
my $conn = DBI->connect("dbi:Pg:dbname=hpkd_db;host=localhost;port=5433;user=malonso;password='manuel'");
my $query;
my @row;
###################

###################
## qurying the Database count real3Dstrs for each HPKD
#$query = $conn->prepare("SELECT hpkd_name, count(need_to_model) as real3Ds from hpkd_templates_seqres ".
$query = $conn->prepare("SELECT hpkd_name, count(need_to_model) as real3Ds from hpkd_templates_realseq ".
                        "WHERE need_to_model='no' ".
                        "GROUP BY hpkd_name ".
                        "ORDER BY real3Ds DESC") or die $conn->errstr;
$query->execute() or die $conn->errstr;
while (@row = $query->fetchrow_array()){
  unless (exists $hpkd_strs_tmpl{$row[0]}){
    $hpkd_strs_tmpl{$row[0]}[0]=0;
    $hpkd_strs_tmpl{$row[0]}[1]=0;
  }
  $hpkd_strs_tmpl{$row[0]}[0]=$row[1];
}
## count templates for each HPKD
#$query = $conn->prepare("SELECT hpkd_name, count(need_to_model) as tomodel from hpkd_templates_seqres ".
$query = $conn->prepare("SELECT hpkd_name, count(need_to_model) as tomodel from hpkd_templates_realseq ".
                        "WHERE need_to_model='yes' ".
                        "GROUP BY hpkd_name ".
                        "ORDER BY tomodel DESC") or die $conn->errstr;
$query->execute() or die $conn->errstr;
while (@row = $query->fetchrow_array()){
  unless (exists $hpkd_strs_tmpl{$row[0]}){
    $hpkd_strs_tmpl{$row[0]}[0]=0;
    $hpkd_strs_tmpl{$row[0]}[1]=0;
  }
  $hpkd_strs_tmpl{$row[0]}[1]=$row[1];
}
## getting the total number of strs/templates = real3D + templates
foreach (keys %hpkd_strs_tmpl){
  $hpkd_strs_tmpl{$_}[2] = $hpkd_strs_tmpl{$_}[0] + $hpkd_strs_tmpl{$_}[1];
}
#foreach (keys %hpkd_strs_tmpl){
  #print "$_\t$hpkd_strs_tmpl{$_}[0]\t$hpkd_strs_tmpl{$_}[1]\t$hpkd_strs_tmpl{$_}[2]\n";
#}
###################

###################
## disconnecting DB
$conn->disconnect();
$conn = undef;
###################

###################
## AGC_AKT__AKT1
## preparing the data and writing out to gnuplot data file 
open(I,"/home/malonso/phd/kinome/hpk/516_hpkd_G_F_SF_P.hpkd_in_fasta_file")or die;
my @classification = <I>;
chomp(@classification);
push(@classification,"#_#_#_#");
close(I);

my %hpkd_group=();
my ($group,$fam,$subfam,$hpkd_classif) = "";
my $prev_group = "";
my $xtics_labels="";
my $index=1;

open(DATAFILE,">data_file_gnuplot.dat") or die;

foreach (@classification){
  ($group,$fam,$subfam,$hpkd_classif) = split("_",$_);
  
  next if($group eq "RGC");

  if($prev_group ne "" && $group ne $prev_group){
    # sort and print out the current data in hash %hpkd_group
    foreach (sort { $hpkd_group{$b}[2] <=> $hpkd_group{$a}[2] } keys %hpkd_group){
      print DATAFILE "$prev_group\t$_\t$index\t$hpkd_strs_tmpl{$_}[0]\t$hpkd_strs_tmpl{$_}[1]\t$hpkd_strs_tmpl{$_}[2]\n";
      $xtics_labels = $xtics_labels."\"$_\" $index,";
      $index++;
    }
    $xtics_labels = $xtics_labels."\"\" $index,"; #  empty tics
    $index++;
    print DATAFILE "\n\n";
    %hpkd_group=();
  }
  foreach my $hpkd_name (keys %hpkd_strs_tmpl){
    $hpkd_group{$hpkd_name}=$hpkd_strs_tmpl{$hpkd_name} if($hpkd_name eq $hpkd_classif);
  }
  $prev_group = $group;
}
chop($xtics_labels);

close(DATAFILE);
###################


###################
## preparing the gnuplot script file from a template
open(TEMPLATE,"/home/malonso/phd/kinome/scripts/plot_realseq-seqres_strs-tmp_hpkd_TEMPLATE.gnuplot") or die;
open(SCRIPT,">gnuplot.script") or die;

while(<TEMPLATE>){
  chomp;
  s/XTICS_LABELS/$xtics_labels/;
  s/GNUPLOT_DATA_FILE/data_file_gnuplot.dat/;
  print SCRIPT "$_\n";
}
close(TEMPLATE);
close(SCRIPT);
###################

#################
### Executing gnuplot
system("gnuplot gnuplot.script");
#################

