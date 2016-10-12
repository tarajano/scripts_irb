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
# ./script 875strs.list scanpdb.merged
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
## Reading input file with the list of strs/tmplts files
##
print "loading list\n";
open(I,$ARGV[0]) or die;
my @hpkd_model_list = <I>;
chomp(@hpkd_model_list);
close(I);
@hpkd_model_list = uniq(@hpkd_model_list);
################

################ 
## Reading scanpdb merged results
##
print "loading scanpdb\n";
open(I,$ARGV[1]) or die; # scanpdb.merged file
my @scanpdb = <I>;
chomp(@scanpdb);
close(I);
@scanpdb = uniq(@scanpdb);
################

################
## Counting real 3D strs for each hpkd
##
print "counting complete 3D strs\n";

my @model_classif;
my @scanpdb_fields;
my %hpkd_complete3D=();
my ($hpkd_model,$pdbid_model);
my ($hpkd_scanpdb,$pdbid_scanpdb,$si,$qc);

my $count=1;

foreach (@hpkd_model_list){
  my $flag_hpkd=0;

  ## AGC_AKT__AKT1_3cquA
  @model_classif = split("_",$_);
  ($hpkd_model,$pdbid_model) = ($model_classif[3],$model_classif[4]);
  chop($pdbid_model); # removing the chain id
  $hpkd_complete3D{$hpkd_model}=0 if(! exists $hpkd_complete3D{$hpkd_model});
  
  foreach (@scanpdb){
    ## AGC_AKT__AKT1  259 3cqu  A 319 258 259 259 1 259 7 265 99.6  100.0 81.2  3e-120
    @scanpdb_fields = split("\t",$_);
    my @tmp = split("_",$scanpdb_fields[0]);
    $hpkd_scanpdb = $tmp[3];
    
    $pdbid_scanpdb = $scanpdb_fields[2];
    $si = $scanpdb_fields[12];
    $qc = $scanpdb_fields[13];
    
    if($hpkd_model eq $hpkd_scanpdb){
      $flag_hpkd++;
      if($pdbid_model eq $pdbid_scanpdb && $si==100 && $qc==100){
        $hpkd_complete3D{$hpkd_model}++;
        last;
      }
    }else{last if($flag_hpkd > 0);}
  }
}

##foreach (sort {$hpkd_complete3D{$b} <=> $hpkd_complete3D{$a}} keys %hpkd_complete3D){
  ##print "$_\t$hpkd_complete3D{$_}\n";
##}

##
## Data Stored in:
## $hpkd_complete3D{$hpkd}==complete3Dstructures
################

################
## Counting strs/tmplts for each hpkd
##
print "counting total strs/tmplts\n";

foreach(@hpkd_model_list){
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
print "Creating the gnuplot data file\n";

## The $index variable will be used as the X-value for plotting index-vs-strs/tmplts and
## also for creating the xtics labelling
my $index=1;
my $grp_flag="";
my $xtics_labels="";

open (DAT,">$gnuplot_data_file") or die;
foreach my $grp (sort keys %grp_prot_strs){
  unless ($grp =~ /ATYPICAL/i){
    foreach my $hpkd (sort {$grp_prot_strs{$grp}{$b} <=> $grp_prot_strs{$grp}{$a}} keys %{$grp_prot_strs{$grp}}){
      ## grp_prot_strs{grp}{hpkd}=strs
      ## grp hpkd index strs
      print DAT "$grp\t$hpkd\t$index\t$grp_prot_strs{$grp}{$hpkd}\t$hpkd_complete3D{$hpkd}\n";
      $xtics_labels = $xtics_labels."\"$hpkd\" $index,";
      $index++;
    }
    print DAT "\n\n";
  }
}
## Atypical HPKD at the end of the data file
foreach my $grp (sort keys %grp_prot_strs){
  if ($grp =~ /ATYPICAL/i){
    foreach my $hpkd (sort {$grp_prot_strs{$grp}{$b} <=> $grp_prot_strs{$grp}{$a}} keys %{$grp_prot_strs{$grp}}){
      print DAT "$grp\t$hpkd\t$index\t$grp_prot_strs{$grp}{$hpkd}\t$hpkd_complete3D{$hpkd}\n";
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
print "Creating the gnuplot script file\n";

open(I,"/home/malonso/phd/kinome/scripts/boxes_plot_template.gnuplot") or die; # open gnuplot template file
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

#################
### Executing gnuplot
print "Executing gnuplot\n";
system("gnuplot $gnuplot_script_file");
#################













