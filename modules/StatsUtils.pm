# created on: 16/Feb/2012 by M.Alonso
#
# USAGE:
#   PERL5LIB env variable:
#    update PERL5LIB variable in .bashrc
#    export PERL5LIB=${PERL5LIB}:/home/malonso/phd/kinome/scripts/modules/
#
# CALLING MODULE
#   use StatsUtils;
#

use strict;
use warnings;
use Statistics::R;


require Exporter;
package StatsUtils;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(
                      compute_jaccard_index
                      
                      plot_linear_correlation
                      compute_linear_correlation
                      
                      fisher_test
                      fisher_test_v2
                      
                      compute_adjusted_pvalues
                      compute_pvalue_from_bg_dist
                    );    # Symbols to be exported by default
#

##############################
##  Description
##  Computes Jaccard index given two arrays
##  
## Input: 
##  - Refs. to two arrays
##  
## Returns:
##  - a Jaccard index
##  
## Usage:
##  
##  my $Ji = compute_jaccard_index(\@a1,\@a2);
##  
sub compute_jaccard_index{
  use List::Compare qw(get_intersection get_union);
  
  my @a1 = @{$_[0]};
  my @a2 = @{$_[1]};
  my ($list_compare, $Jaccard_index);
  my (@intersection, @union);
  
  ### Computing intersection between two arrays
  $list_compare = List::Compare->new('--unsorted', '--accelerated',\@a1, \@a2);
  @intersection = $list_compare->get_intersection;
  
  ### Computing union of two arrays
  $list_compare = List::Compare->new('--unsorted', '--accelerated',\@a1, \@a2);
  @union = $list_compare->get_union;
  
  if( 0 == scalar @union || 0 == scalar @intersection){
    return 0;
  }else{
    $Jaccard_index = @intersection/@union;
    return $Jaccard_index;
  }
  
}
##############################


##############################
##  Description
##  Computes linear correlations based on two input arrays of the same size.
##  
## Input: 
##  - Refs. to two arrays containing the values of the variables
##  - label for X values
##  - label for Y values
##  - label for Main Title
##  - full path to output file
##  
## Output:
##    
## Usage:
##  
##  compute_linear_correlation(\@a1,\@a2, 'x_label', 'y_label', 'title', 'path.pdf');
##  
sub plot_linear_correlation{
  my @values1 = @{$_[0]};
  my @values2 = @{$_[1]};
  my $x_label = $_[2];
  my $y_label = $_[3];
  my $main_title = $_[4];
  my $path = $_[5];
  my $R = Statistics::R->new(r_bin => "/usr/bin/R");
  
  $R->set('values1', \@values1);
  $R->set('values2', \@values2);
  $R->set('Xlab', $x_label);
  $R->set('Ylab', $y_label);
  $R->set('MainTitle', $main_title);
  $R->set('PDFoutfile', $path);
  
  
  $R->run(q` pdf(PDFoutfile) `);
  $R->run(q` plot(values1, values2, main=MainTitle, xlab=Xlab, ylab=Ylab) `);
  $R->run(q` abline( lm(values2 ~ values1), col='red') `);
  $R->run(q` dev.off() `);
  
  $R->stop();
  return 0;
}
##############################


##############################
##  Description
##  Computes linear correlations based on two input arrays of the same size.
##  
## Input: 
##  - Refs. to two arrays containing the values of the variables
##  - Correlation method: "spearman" (default) "pearson" or "kendall"
##  - Test type: "two.sided"  (default) "greater" or "less"
##  
## Output:
##  - Array containing:
##    - Correlation Coeff
##    - Pvalue of the Correlation Coeff
##    
## Usage:
##  
##  ($corr, $cor_pvalue) = compute_linear_correlation(\@a1,\@a2, 'pearson', 'two.sided');
##  
sub compute_linear_correlation{
  my @values1 = @{$_[0]};
  my @values2 = @{$_[1]};
  my $corr_method = $_[2] || 'spearman';  ### "pearson", "kendall", "spearman"
  my $alternative = $_[3] || 'two.sided'; ### "two.sided", "greater" or "less"
  
  my ($correlation, $pvalue);
  
  my $R = Statistics::R->new(r_bin => "/usr/bin/R");
  $R->set('values1', \@values1);
  $R->set('values2', \@values2);
  $R->set('corr_method', $corr_method);
  $R->set('alternative', $alternative);
  $R->run(q` myc =  cor.test(values1,values2,alternative=alternative, method=corr_method)`);
  
  $pvalue = $R->get('myc$p.value');
  $correlation = $R->get('myc$estimate');
  
  $R->stop();
  return ($correlation, $pvalue);
}
##############################

##############################
##  Computing the pvalue for an input value given a BG null distribution.
##  
## Input: 
##  - Ref. to array containing a null distribution
##  - A value for which to compute the pvalue
##  
## Output:
##  - the pvalue
##  
## Usage:
##  pvalue = compute_pvalue_from_bg_dist(\@bgdist, value)
##  
##  
sub compute_pvalue_from_bg_dist{
  my @bgdist = @{$_[0]};
  my $value = $_[1];
  my $pvalue;
  
  my @lt_values = grep {$_ >= $value} @bgdist;
  $pvalue = sprintf ("%.4f", scalar @lt_values / scalar @bgdist);
  
  return $pvalue;
}
##############################


##############################
## Correcting pvalues for multiple testing
##
## Input: 
## A reference to an array of pvalues
## Output:
## An array of two refs to arrays
##
## Fetching output:
## @tmp = compute_adjusted_pvalues(\@rawpvalues);
## @B = @{$tmp[0]};
## @BH = @{$tmp[1]};
##
sub compute_adjusted_pvalues{
  my @raw_pvalues = @{$_[0]};
  my $R = Statistics::R->new(r_bin => "/usr/bin/R");
  $R->set('raw_pvalues', \@raw_pvalues);
  $R->run(q`pvalues_adjusted_Bonferroni = p.adjust(raw_pvalues, method="bonferroni") `);
  $R->run(q`pvalues_adjusted_BH = p.adjust(raw_pvalues, method="BH") `);
  my @pvalues_adjusted_Bonferroni = @{$R->get('pvalues_adjusted_Bonferroni')};
  my @pvalues_adjusted_BH = @{$R->get('pvalues_adjusted_BH')};
  $R->stop();
  return (\@pvalues_adjusted_Bonferroni,\@pvalues_adjusted_BH);
}
##############################

##############################
## Computing Fisher's exact test
## 
## USAGE:
## $pvalue = fisher_test_v2(\@data, "greater")
##
## @data must contain the data for creating the 2x2 contingency table:
## @data = (r1c1, r1c2, r2c1, r2c2)
## @data = (TP, FN, FP, TN)
## 
#####   Contingency Table
###   
###   | Y  |  N |
### ----------------
### Y | TP | FN |  
###  --------------  
### N | FP | TN |    
###  --------------
### 
## INPUT:
## ARG1: A ref to an array with data for the test
## ARG2: whether the test is:
##       two.sided -> "two.sided"
##       right tail -> "greater"
##       left tail -> "less"
## 
## RETURNS:
## the pvalue
##

sub fisher_test_v2{
  my @data = @{$_[0]};
  my $alternative = $_[1];
  die unless (4 == scalar(@data) && defined $alternative);
  
  my $R = Statistics::R->new(r_bin => "/usr/bin/R");
  $R->set( 'fisher_test_data', \@data);
  $R->set( 'alternative', $alternative);
  $R->run( q`contingency_table = matrix(fisher_test_data, nr=2, byrow=T)`);
  $R->run( q`fisher_t_results = fisher.test(contingency_table, alternative=alternative)`);
  my $fisher_test_pvalue = $R->get('fisher_t_results$p.value');
  my $odds_ratio = $R->get('fisher_t_results$estimate');
  $R->stop();
  return [$fisher_test_pvalue, $odds_ratio];
}
##############################

##############################
## Computing Fisher's exact test
## 
## USAGE:
## $pvalue = fisher_test(\@data, "greater")
##
## @data must contain the data for creating the 2x2 contingency table:
## @data = (r1c1, r1c2, r2c1, r2c2)
##
## INPUT:
## ARG1: A ref to an array with data for the test
## ARG2: whether the test is:
##       two.sided -> "two.sided"
##       right tail -> "greater"
##       left tail -> "less"
## 
## RETURNS:
## the pvalue
##

sub fisher_test{
  my @data = @{$_[0]};
  my $alternative = $_[1];
  die unless (4 == scalar(@data) && defined $alternative);
  
  my $R = Statistics::R->new(r_bin => "/usr/bin/R");
  $R->set( 'fisher_test_data', \@data);
  $R->set( 'alternative', $alternative);
  $R->run( q`contingency_table = matrix(fisher_test_data, nr=2)`);
  $R->run( q`fisher_t_results = fisher.test(contingency_table, alternative=alternative)`);
  my $fisher_test_pvalue = ${$R->get('fisher_t_results[1]')}[1];
  #my $fisher_test_pvalue = ${$R->get('fisher_t_results$p.value')}[1];
  #my $odds_ratio = ${$R->get('fisher_t_results$estimate')}[1];
  $R->stop();
  return $fisher_test_pvalue;
  
  #return [$fisher_test_pvalue, $odds_ratio];
}
##############################

1;
