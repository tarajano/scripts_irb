#!/usr/bin/env perl
#
#
# created on: 24/Jan/2011 by M.Alonso
#
# fetching the results from DALI and RAPIDO output files 
#
#
#
#
use strict;
use warnings;

my @fields;

##
my %dali_str1_str2_rmsd=(); #{str1}{str2}=(output data from dali)
my %rapido_str1_str2_rmsd=(); #{str1}{str2}=(output data from dali)


######################
## File containing the paths to all summary files
print "loading dali files list\n";
my @summary_files;
open(F,"/aloy/scratch/malonso/struct_alignments/daliLite/paths_to_summaries.10.txt");
@summary_files=<F>;
chomp(@summary_files);
@summary_files = sort (@summary_files);
close(F);
######################

#######################
### File containing the paths to all XML files
#print "loading rapido files list\n";
#my @xml_files;
#open(F,"/aloy/scratch/malonso/struct_alignments/rapido/paths_to_xmls.txt");
#@xml_files=<F>;
#chomp(@xml_files);
#@xml_files = sort (@xml_files);
#close(F);
#######################

######################
## loading DALI data
print "loading dali data\n";
foreach my $sumfile (@summary_files){
  @fields = split("/",$sumfile);
  my ($str1,$str2) = split("_vs_", $fields[-2]);
  $dali_str1_str2_rmsd{$str1}{$str2} = parse_summary_file($sumfile);
  #printf("%s\n",join("\t",$str1,$str2, join("\t",@{$dali_str1_str2_rmsd{$str1}{$str2}})));
}
######################

#######################
### loading RAPIDO data
#print "loading rapido data\n";
#foreach my $xmlfile (@xml_files){
  #@fields = split("/",$xmlfile);
  #my ($str1,$str2) = split("_vs_", $fields[-2]);
  #$rapido_str1_str2_rmsd{$str1}{$str2} = parse_xml_file($xmlfile);
  ##printf("%s\n",join("\t",$str1,$str2,$rapido_str1_str2_rmsd{$str1}{$str2}));
#}
#######################

######################
#print "priting to file\n";
#my ($k1,$k2);
#open(O,">/aloy/scratch/malonso/struct_alignments/rapido_vs_dali_rigid_rmsd_all_scatter_plot.dat") or die;
#foreach $k1 (sort {$a cmp $b} keys %dali_str1_str2_rmsd){
  #foreach $k2 (sort {$a cmp $b} keys %{$dali_str1_str2_rmsd{$k1}}){
    #printf O ("%s\n",join("\t",$k1,$k2,$rapido_str1_str2_rmsd{$k1}{$k2},$dali_str1_str2_rmsd{$k1}{$k2}));
  #}
#}
#close(O);
######################

#############################
###### Subroutines ##########
#############################

#############################
## Parsing RAPIDO XML files
sub parse_xml_file{
  my $xmlfile = $_[0];

  ## retrieving rmsd
  open(I,$xmlfile) or die;
  while(<I>){
    if(/<rmsd>(\d+\.\d+)<\/rmsd>/){
      return $1;
      last;
    }
  }
  close(I);
}
#############################

#############################
## Parsing DALI summary file
##
sub parse_summary_file{
  my $summary_file = $_[0];
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
  
  return (\@summary_data);
}
#############################
