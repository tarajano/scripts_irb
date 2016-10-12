#!/usr/bin/env perl
#
# counting how meny 3D strs/templs per hpkd
#
# input file (875strs.list)
#AGC_AKT__AKT1_3cquA
#AGC_AKT__AKT1_3cqwA
#AGC_AKT__AKT1_3mv5A
#AGC_AKT__AKT1_3mvhA
#AGC_AKT__AKT2_1o6kA
#AGC_AKT__AKT2_1o6lA
#AGC_AKT__AKT2_2jdoA
#
# ./script 875strs.list
#
#

use strict;
use warnings;
use List::MoreUtils qw(uniq);

my %hpkd_strs=();
my $gnuplot_output_file=$ARGV[0];
my $gnuplot_data_file=$ARGV[0].".dat";
my $gnuplot_script_file=$ARGV[0].".gnuplot";

################ 
## Reading input file
##
open(I,$ARGV[0]) or die;
my @infile = <I>;
chomp(@infile);
close(I);
@infile = uniq(map(uc($_),@infile));
################

################
## Counting strs/tmplts for each hpkd
##
foreach(@infile){
  chomp;
  my @fields = split("_",$_);
  my $hpkd = join("_",@fields[0..3]); # GRP_FAM_SUBFAM_HPKD
  if(exists $hpkd_strs{$hpkd}){$hpkd_strs{$hpkd}++;}
  else{$hpkd_strs{$hpkd}=1;}
}
##printf("hpkds %d\n",scalar(keys %hpkd_strs));
##print "$_\t$hpkd_strs{$_}\n" foreach(sort {$a cmp $b} keys %hpkd_strs);
################
## Creating a {grp}{hpkd}=strs/tmplts datastructure to be used for 
## generating the data file for gnuplot
my %grp_prot_strs=();
foreach my $classif (keys %hpkd_strs){
  my @classif = split("_",$classif); #GRP_FAM_SUBFAM_HPKD
  $grp_prot_strs{$classif[0]}{$classif[3]}=$hpkd_strs{$classif}; # {grp}{hpkd}=strs
}
################

################
## Creating the gnuplot data file
## Sorting the datastructure {grp}{hpkd}=strs/tmplts by the number of available strs/tmplts
## Printing Atypical HPK at the end of the data file
##

## The $index variable will be used as the X-value for plotting index-vs-strs/tmplts and
## also for creating the xtics labelling
my $index=1;
my $grp_flag="";
my $xtics_labels="";

open (DAT,">$gnuplot_data_file") or die;
foreach my $grp (sort keys %grp_prot_strs){
  unless ($grp eq "ATYPICAL"){
    foreach my $hpkd (sort {$grp_prot_strs{$grp}{$b} <=> $grp_prot_strs{$grp}{$a}} keys %{$grp_prot_strs{$grp}}){
      ## grp_prot_strs{grp}{hpkd}=strs
      ## grp hpkd index strs
      print DAT "$grp\t$hpkd\t$index\t$grp_prot_strs{$grp}{$hpkd}\n";
      $xtics_labels = $xtics_labels."\"$hpkd\" $index,";
      $index++;
    }
    print DAT "\n\n";
  }
}
## Atypical HPKD at the end of the data file
foreach my $grp (sort keys %grp_prot_strs){
  if ($grp eq "ATYPICAL"){
    foreach my $hpkd (sort {$grp_prot_strs{$grp}{$b} <=> $grp_prot_strs{$grp}{$a}} keys %{$grp_prot_strs{$grp}}){
      print DAT "$grp\t$hpkd\t$index\t$grp_prot_strs{$grp}{$hpkd}\n";
      $xtics_labels = $xtics_labels."\"$hpkd\" $index,";
      $index++;
    }
  }
}
close(DAT);

## remove trailing "," from xtics_labels
chop ($xtics_labels);
################

################
## Creating (from a template) the gnuplot script
##
open(I,"barplot_template.gnuplot") or die; # open gnuplot template file
open(O,">$gnuplot_script_file") or die;
while(<I>){
  if($_ =~ /XTICS_LABELS/){$_ =~ s/XTICS_LABELS/$xtics_labels/;}
  elsif($_ =~ /GNUPLOT_DATA_FILE/){$_ =~ s/GNUPLOT_DATA_FILE/$gnuplot_data_file/;}
  elsif($_ =~ /GNUPLOT_OUTPUT_FILE/){$_ =~ s/GNUPLOT_OUTPUT_FILE/$gnuplot_output_file/;}
  print O "$_";
}
close(I);
close(O);
################

################
## Executing gnuplot
system("gnuplot $gnuplot_script_file");
################













