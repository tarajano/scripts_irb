#!/usr/bin/env perl
#
# created on: 27/Jan/2011 by M.Alonso
#
# Parsing XML from RAPIDO
#
# This script can be used to create an ArrayJob. 
# setupArrayJobMod.py -N jobname -l summaries_paths.list -t #tasks thisscript.pl $i 
#
# INPUT:
# a file with a list of paths to XML files
#
# OUTPUT
# One file per each xml input file containing the data parsed
#

use strict;
use warnings;
use XML::Simple;

my $outdir = "/aloy/scratch/malonso/struct_alignments/rapido/collect_data/outs/";
my @fields;
my ($str1,$str2);

open(LIST,$ARGV[0]) or die;
my @xmls=<LIST>;
chomp(@xmls);
close(LIST);


foreach my $xmlfile (@xmls){
  @fields = split("/",$xmlfile);
  ($str1,$str2) = split("_vs_", $fields[-2]);
  parse_XmlSimple_file($xmlfile,$str1,$str2);
}

#############################
## Parsing the XML files from RAPIDO
## The order of values in the returned (printed) array is:
## rmsd num_aligned len1 len2 lo_lim hi_lim flex_rmsd num_rigid_bodies num_rigid_pairs status rb_1_dim rb_1_rmsd rb_2_dim rb_2_rmsd rb_N_dim rb_N_rmsd 
sub parse_XmlSimple_file{
  my (@rb_s,@xml_tmp_data,@xml_data);
  my ($str1,$str2) = ($_[1],$_[2]);
  
  ## Creating XMLSimple object & hash datastructure
  my $r = (XML::Simple->new()->XMLin($_[0]));
  my %h1 = %{$r};
  
  ## Access the 1st level of the data structure
  foreach my $k1 (keys %h1){
    next if ($k1 eq "type");
    ## Parse the 'alignment' section of the RAPIDO xml file 
    if($k1 eq "alignment"){
      my %h2 = %{$h1{$k1}};
      ## Access the 2nd level of the data structure
      foreach my $k2 (sort {$a cmp $b} keys %h2){
        if($k2 eq "len1" || $k2 eq "len2" || $k2 eq "status" || $k2 eq "num_aligned" || $k2 eq "lo_lim" || $k2 eq "hi_lim" || $k2 eq "rmsd" || $k2 eq "flex_rmsd" || $k2 eq "num_rigid_bodies" || $k2 eq "num_rigid_pairs"){
          $h2{$k2}=0 if ($h2{$k2} eq "");
          push(@xml_tmp_data,$h2{$k2});
          #print "\t$k2\t$h2{$k2}\n";
        }elsif($k2 eq "rb_1" || $k2 eq "rb_2" || $k2 eq "rb_3" || $k2 eq "rb_4" || $k2 eq "rb_5" || $k2 eq "rb_6" || $k2 eq "rb_7" || $k2 eq "rb_8" || $k2 eq "rb_9"){
          ## WARNING: In the previous line, in order to avoid pattern matching I've set "enough" rigid bodies
          ## storing rigid bodies labels
          push(@rb_s,$k2);
        }
      }
      ## Accessing rigid bodies data
      foreach my $rb (@rb_s){
        my %h3 = %{$h2{$rb}};
        ## Access the 3nd level of the data structure. Rigid Bodies.
        foreach my $k3 (sort {$a cmp $b} keys %h3){
          if($k3 eq "dim" || $k3 eq "rmsd"){
            $h3{$k3}=0 if ($h3{$k3} eq "");
            push(@xml_tmp_data,$h3{$k3});
          }
        }
      }
      last;
    }
  }
  #########
  ## Ordering array
  ## rmsd num_aligned len1 len2 lo_lim hi_lim flex_rmsd num_rigid_bodies num_rigid_pairs status rb_1_dim rb_1_rmsd rb_2_dim rb_2_rmsd rb_N_dim rb_N_rmsd 
  $xml_data[0] = $xml_tmp_data[8]; # rmsd
  $xml_data[1] = $xml_tmp_data[5]; # num_aligned
  $xml_data[2] = $xml_tmp_data[2]; # len1
  $xml_data[3] = $xml_tmp_data[3]; # len2
  $xml_data[4] = $xml_tmp_data[4]; # lo_lim
  $xml_data[5] = $xml_tmp_data[1]; # hi_lim
  $xml_data[6] = $xml_tmp_data[0]; # flex_rmsd
  $xml_data[7] = $xml_tmp_data[6]; # num_rigid_bodies
  $xml_data[8] = $xml_tmp_data[7]; # num_rigid_pairs
  $xml_data[9] = $xml_tmp_data[9]; # status
  push(@xml_data,@xml_tmp_data[10 .. $#xml_tmp_data]); #  rb_1_dim rb_1_rmsd rb_2_dim rb_2_rmsd rb_N_dim rb_N_rmsd 
  #########
  
  my $outfilename=$outdir."$str1"."_vs_"."$str2";
  open(O,">$outfilename") or die;
  printf O ("%s\n",join("\t",$str1,$str2,@xml_data));
  close(O);
  #return @xml_data;
}
#############################


