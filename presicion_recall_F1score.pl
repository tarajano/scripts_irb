#!/usr/bin/env perl
#
# created on: 11/Apr/2012 by M.Alonso
#
# Computing precision and recall of AS for kinases
#
#
# ./script inputfile ## inputfile is the output of the script "computing_statsignif_of_pAS.pl"
#
#

use strict;
use warnings;
use LoadFile;
use List::Compare qw(get_intersection);

my ($recall, $precision, $recalled_fraction, $f1_score, $list_compare, $interactor_signif, $as_signif_fraction);
my (@fields, @significant_interactors, @known_pk_scaffold_adaptor, @intersection);

my %known_pk_scaffold_adaptor; ## {pk}=[ACs]
my %results_pk_scaffold_adaptor; ## {fam}{pk}=[ACs]

##############################
## Loading known scaffolds
foreach(File2Array("/home/malonso/phd/kinome/scaffolds/scaffolds_adaptors_among_hpk_interactors/scaffolds_adaptors_among_hpk_interactors.pl.cleaned.tab.acs",1)){
  ## fam  pk-ID pk-AC pk_adp-scaf-AC  pk_adp-scaf-ID  pk_adp-scaf_type
  @fields = splittab($_);
  ## {pk}=[ACs]
  push (@{$known_pk_scaffold_adaptor{$fields[2]}}, $fields[3]);
}
##############################

##############################
## Loading results
my $script_results_file = $ARGV[0] or die; ## output of script.pl [subs_5_interactome_script.tab]
foreach(File2Array($script_results_file,1)){
  ## fam  pk  pk_subs subs_partner  is_pk_AS  freq  pvalue
  @fields = splittab($_);
  push (@{$results_pk_scaffold_adaptor{$fields[0]}{$fields[1]}}, $fields[3]); ## {fam}{pk}=[interactors]
}
##############################

compute_print_recall_presicion_f1score();

##############################
######## SUBROUTINES #########
##############################

##############################
sub compute_print_recall{
  open(O, ">$0.f1score") or die;
  printf O ("%s\n", jointab(qw(Family Kinase Int-Signif AS-Fract-Signif AS-Recall AS-Recalled)) );
  foreach my $fam (sort keys %results_pk_scaffold_adaptor){
    foreach my $pk (sort keys %{$results_pk_scaffold_adaptor{$fam}} ){
      next unless(exists $known_pk_scaffold_adaptor{$pk});
      ##
      @significant_interactors = @{$results_pk_scaffold_adaptor{$fam}{$pk}};
      @known_pk_scaffold_adaptor = @{$known_pk_scaffold_adaptor{$pk}};
      $list_compare = List::Compare->new('--unsorted', '--accelerated',\@significant_interactors, \@known_pk_scaffold_adaptor);
      @intersection = $list_compare->get_intersection;
      
      $interactor_signif = scalar @significant_interactors;
      $as_signif_fraction = sprintf("%.2f", @intersection/@significant_interactors);
      
      ## Computing presicion and recall and f1score
      $recall = sprintf("%.2f", scalar (@intersection)/scalar(@known_pk_scaffold_adaptor));
      $recalled_fraction = scalar (@intersection)."/".scalar(@known_pk_scaffold_adaptor);
      printf O ("%s\n", jointab($fam, $pk, $interactor_signif, $as_signif_fraction, $recall, $recalled_fraction));
    }
  }
  close(O);
}
##############################

##############################
sub compute_print_recall_presicion_f1score{
my ($signif_interactors ,$known_AS, $identif_AS, $AS_recalled);

  open(O, ">$script_results_file.f1score") or die;
  printf O ("%s\n", jointab(qw(Family Kinase Sig.Inter AS-recalled AS-recall AS-precision AS-F1-score)) );
  foreach my $fam (sort keys %results_pk_scaffold_adaptor){
    foreach my $pk (sort keys %{$results_pk_scaffold_adaptor{$fam}} ){
      next unless(exists $known_pk_scaffold_adaptor{$pk});
      ##
      @significant_interactors = @{$results_pk_scaffold_adaptor{$fam}{$pk}};
      @known_pk_scaffold_adaptor = @{$known_pk_scaffold_adaptor{$pk}};
      $known_AS = scalar @known_pk_scaffold_adaptor;
      $signif_interactors = scalar @significant_interactors;
      
      $list_compare = List::Compare->new('--unsorted', '--accelerated',\@significant_interactors, \@known_pk_scaffold_adaptor);
      @intersection = $list_compare->get_intersection;
      $identif_AS = scalar @intersection;
      
      ## Computing presicion and recall and f1score
      $recall = sprintf("%.2f", scalar (@intersection)/scalar(@known_pk_scaffold_adaptor));
      $precision = sprintf("%.2f", scalar(@intersection)/scalar(@significant_interactors));
      next if($precision==0 && $recall==0);
      $f1_score = sprintf("%.2f", 2*($precision * $recall)/($precision + $recall));
      $AS_recalled = join("/", $identif_AS, $known_AS);
      printf O ("%s\n", jointab($fam,$pk,$signif_interactors,$AS_recalled,$recall,$precision,$f1_score));
    }
  }
  close(O);
}
##############################











