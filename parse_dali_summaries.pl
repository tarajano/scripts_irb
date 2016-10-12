#!/usr/bin/env perl
#
# created on: 28/Jan/2011 by M.Alonso
#
# This script can be used to create an ArrayJob. 
# setupArrayJobMod.py -N jobname -l summaries_paths.list -t #tasks thisscript.pl $i 
#
# INPUT:
# A file with a list of paths to Summary.txt files
#
# OUTPUT
# One file per each summary input file containing the data parsed
# 
# 

use strict;
use warnings;


my $outdir = "/aloy/scratch/malonso/struct_alignments/daliLite/collect_data/outs/";
my ($str1,$str2);

open(LIST,$ARGV[0]) or die;
my @sums=<LIST>;
chomp(@sums);
close(LIST);


foreach my $sum (@sums){
  my @field = split("/",$sum);
  ($str1,$str2) = split("_vs_", $field[-2]);
  parse_summary_file($sum,$str1,$str2);
}

#############################
## Parsing DALI summary file
## 
## The order of values in the returned (printed) array is:
## Z-score rmsd lali nres %id
## 

sub parse_summary_file{
  my $summary_file = $_[0];
  my ($str1,$str2) = ($_[1],$_[2]);
  my @fields;
  my @summary_data;
  
  ## retrieving rmsd values
  my $line = `sed -n '3p' $summary_file`;
  chomp($line);
  @fields = split(' +',$line);
  if($#fields > 0 && defined $fields[3]){
    ## Cheking if Z-value exists in summary.txt file.
    ## Remember that if Z-value < 2 ("Similarities with a Z-score lower than 2 are spurious", ekhidna.biocenter.helsinki.fi/dali_server)
    ## Z rmsd lali nres %id
    @summary_data = ($fields[3],$fields[4],$fields[5],$fields[6],$fields[7]);
  }else{
    # For structures that Dali fails to compute the rmsd RAPIDO assigns rigid rmsd > 10 Angstroms,
    # following this I assign the arbitrary value of 15 Angstrom of RMSD for those structures pairs that Dali fails to compute RMSD.
    @summary_data = (0,15,0,0,0);
  }
  
  my $outfilename=$outdir."$str1"."_vs_"."$str2";
  open(O,">$outfilename") or die;
  printf O ("%s\n",join("\t",$str1,$str2,@summary_data));
  close(O);
  
  #return (\@summary_data);
}
#############################
