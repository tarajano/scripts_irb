#!/usr/bin/env perl
#
# created on: 07/Dec/2011 by M.Alonso
#
#  Computing Pearson Corr. Coeff., Spearman Ranked Corr. Coeff. and 
#  their respective pvalues for kinase family pairs with 3 or more 
#  comparisons between them and for which neither the number of
#  shared PPIs nor the number of shared Substrates is Zero.
#
#
#  Usage:
#  This script is meant to be used giving as input the results file of the scripts:
#    'within_hpkfams_shared_partners_shared_substrates.pl'
# i.e: 
#    ./compute_Pearson_Spearman_pvalues.pl within_hpkfams_shared_partners_shared_substrates.tab
#

use strict;
use warnings;
use LoadFile;
use Statistics::R;

my ($pk, $shared_ppis, $shared_subs, $pearson, $spearman, $pearson_pvalue, $spearman_pvalue, $tmp);

my (@fields, @hpkfams, @pearson, @spearman, @pearson_pvalues, @spearman_pvalues, @pearson_pvalues_adj, @spearman_pvalues_adj);

my %hpkfam_shared_ppi_subs; ## {pkfam}{pk1-pk2}=[shared_ppi, shared_subs]

##############################
## Loading file with the comparisons between kinases/kinases families
## and their numbers of shared partners and substrates.
## Format: hpkfamily	sharedpartners	sharedsubstrates
##
foreach (File2Array($ARGV[0],1)){
  ($pk, $shared_ppis, $shared_subs) = splittab($_);
  push(@{$hpkfam_shared_ppi_subs{$pk}[0]}, $shared_ppis);
  push(@{$hpkfam_shared_ppi_subs{$pk}[1]}, $shared_subs);
}
##############################

##############################
##  Computing Determinant Regression Coef. and Spearman Ranked Coefficient
##  for kinase family pairs with 3 or more comparisons between them
##  and for which neither the number of shared PPIs nor the number
##  of shared Substrates is Zero.
##

## Creating name of the output file
my $output_file;
@fields = splitdot($ARGV[0]);
$output_file = $fields[0].".coefs";

## Creating R object
my $R = Statistics::R->new(r_bin => "/usr/bin/R");


foreach my $fam (sort {$a cmp $b} keys %hpkfam_shared_ppi_subs){
  ## Skipping families with less than 5 pairs compared.
  next if (5>scalar(@{$hpkfam_shared_ppi_subs{$fam}[0]})); ## useless for correlation analysis
  
  ## Setting R variables
  $R->set( 'shared_ppis', \@{$hpkfam_shared_ppi_subs{$fam}[0]} );
  $R->set( 'shared_subs', \@{$hpkfam_shared_ppi_subs{$fam}[1]} );
  
  ## Computing Pearson and Spearman corr. coeffs.
  $R->run( q`mypearson=round(cor(shared_ppis,shared_subs, method="pearson"),5)`);
  $R->run( q`myspearman=round(cor(shared_ppis,shared_subs, method="spearman"),5)`);
  ## Computing stat. significance of Pearson and Spearman corr. coeffs.
  $R->run( q`mypearson_pvalue=cor.test(shared_ppis,shared_subs, method="pearson")`);
  $R->run( q`myspearman_pvalue=cor.test(shared_ppis,shared_subs, method="spearman")`);
  ## Retrieving correlation coefficients and their p-values
  $pearson = $R->get('mypearson');
  $spearman = $R->get('myspearman');
  
  ## Excluding from the output the cases for which the corr.coeff. can
  ## not be computed.
  if($pearson eq "NA" || $spearman eq "NA"){
    print "WARNING: Correlation coefficients can not be computed for: \"$fam\". \"$fam\" will be excluded from results\n";
    next;
  }
  ## Saving current family.
  push(@hpkfams, $fam);
  
  ## Retrieving p-values of correlation coefficients
  $pearson_pvalue = ${$R->get('mypearson_pvalue[3]')}[1];
  $spearman_pvalue = ${$R->get('myspearman_pvalue[3]')}[1];
  
  ## Saving Pearson and Spearman Coefficients and their raw pvalue
  push(@pearson, $pearson);
  push(@spearman, $spearman);
  push(@pearson_pvalues, $pearson_pvalue);
  push(@spearman_pvalues, $spearman_pvalue);
}

## Adjusting computed pvalues.
$R->set( 'pearson_pvalues', \@pearson_pvalues );
$R->set( 'spearman_pvalues', \@spearman_pvalues );
$R->run(q`pearson_pvalues_adjusted = p.adjust(pearson_pvalues, method="bonferroni") `);
$R->run(q`spearman_pvalues_adjusted = p.adjust(spearman_pvalues, method="bonferroni") `);

## Retrieving adjusted pvalues
@pearson_pvalues_adj = @{$R->get('pearson_pvalues_adjusted')};
@spearman_pvalues_adj = @{$R->get('spearman_pvalues_adjusted')};
$R->stop();
##############################


##############################
## Printing to output.
## I'm not including Spearman corr. coeff. in the output. If needed it
## can be included.

open (O, ">$output_file") or die;
#printf O ("%s\n", join("\t", qw(HPKFAM Pearson Pearson_raw_pvalue Pearson_adjusted_pvalue)));
printf O ("%s\n", join("\t", qw(HPKFAM Pearson Pearson_raw_pvalue Pearson_adjusted_pvalue Spearman Spearman_raw_pvalue Spearman_adjusted_pvalue)));
for(my $i=0;$i<=$#hpkfams;$i++){
  if($spearman[$i] >= 0.6 && $spearman_pvalues_adj[$i] < 0.001){
    #printf O ("%s\n", join("\t", $hpkfams[$i], $pearson[$i]." *", $pearson_pvalues[$i], $pearson_pvalues_adj[$i]));
    printf O ("%s\n", join("\t", $hpkfams[$i], $pearson[$i], $pearson_pvalues[$i], $pearson_pvalues_adj[$i], $spearman[$i]."*", $spearman_pvalues[$i], $spearman_pvalues_adj[$i]));
  }else{
    #printf O ("%s\n", join("\t", $hpkfams[$i], $pearson[$i], $pearson_pvalues[$i], $pearson_pvalues_adj[$i]));
    printf O ("%s\n", join("\t", $hpkfams[$i], $pearson[$i], $pearson_pvalues[$i], $pearson_pvalues_adj[$i], $spearman[$i], $spearman_pvalues[$i], $spearman_pvalues_adj[$i]));
  }
}
close(O);
##############################


