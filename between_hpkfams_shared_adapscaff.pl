#!/usr/bin/env perl
#
# Created on: 20/Dec/2011 by M.Alonso
# This version : 25/May/2011 by M.Alonso
#
#
# This script counts the number of shared adaptors/scaffolds between all
# kinase pairs in our data set.
# The output file 'between_hpkfams_shared_adapscaff.tab' will be used
# for analyzing if kinases from the same family (SF) share significanly
# larger number of adaptors/scaffolds than kinases from different
# families (DF).
#
#
#

use strict;
use warnings;
use LoadFile;
use List::MoreUtils qw(uniq);
use List::Compare qw(get_intersection);

my ($pk, $subs);

my (@fields, @tmp);

my %pk_elements; ## {pk}=[elements]
my %hpkfam_data; ## {pkfam}{pk}=[elements]
my %hpkfam_shared_ppi_subs; ## {pkfam}{pk1-pk2}=[shared_ppi, shared_subs]



###############################
### COLLECTING DATA ON KINASE - ADAPTOR/SCAFFOLD INTERACTIONS
### Collecting adaptors/scaffolds per kinase
### and organizing kinases by family.
@tmp = collect_kinase_adaptorsscaffolds_data();
%hpkfam_data = %{$tmp[0]}; ## {pkfam}{pk}=[elements]
%pk_elements = %{$tmp[1]}; ## {pk}=[elements]
###############################

##############################
## Computing shared elements between every pair
## of kinases.
my ($pk1, $pk2, $shared_elements, $list_compare, $pk_pair, $fam_pair, $fams_in_pair);
my (@pk1_acs, @pk2_acs);

my %hpk_fam_times_compared;
my %hpk_fam_sharing; ## {fam_pair}{pk_pair}=[shared_subs, SF|DF, hpk_fam_times_compared];

my %tmp_hpkfam_data = %hpkfam_data;

foreach my $fam1 (keys %tmp_hpkfam_data){
  my @pks_in_fam1 = keys %{$tmp_hpkfam_data{$fam1}};

  foreach my $fam2 (keys %tmp_hpkfam_data){
    my @pks_in_fam2 = keys %{$tmp_hpkfam_data{$fam2}};
    my $fam_pair = join("-", $fam1, $fam2);
        
    ## If the families are the same or not
    if($fam1 eq $fam2){$fams_in_pair="SF";}
    else{$fams_in_pair="DF";}
    
    foreach $pk1 (@pks_in_fam1){
      foreach $pk2 (@pks_in_fam2){
        next if ($pk1 eq $pk2);
        
        ## Counting the times a pair of families has been compared from 
        ## their corresponding members.
        if(exists $hpk_fam_times_compared{$fam_pair}){$hpk_fam_times_compared{$fam_pair}++;}
        else{$hpk_fam_times_compared{$fam_pair}=1;}
        
        ## Fetching substs of current PK pair
        @pk1_acs = @{$hpkfam_data{$fam1}{$pk1}}; ## PK1 subs
        @pk2_acs = @{$hpkfam_data{$fam2}{$pk2}}; ## PK2 subs
        ### Computing the intersection
        $list_compare = List::Compare->new(\@pk1_acs, \@pk2_acs);
        $shared_elements = scalar($list_compare->get_intersection);
        $pk_pair = join("-", $pk1, $pk2);
        $hpk_fam_sharing{$fam_pair}{$pk_pair}=[$shared_elements,$fams_in_pair];
      }
    }
  }
  ## For speeding next iteration
  delete $tmp_hpkfam_data{$fam1}; 
}
##############################

##############################
## Adding the times a family pair had been compared.
foreach $fam_pair (keys %hpk_fam_sharing){
  foreach $pk_pair (keys %{$hpk_fam_sharing{$fam_pair}}){
    push(@{$hpk_fam_sharing{$fam_pair}{$pk_pair}}, $hpk_fam_times_compared{$fam_pair});
  }
}
##############################


################################
### Printing to data file
open(O,">between_hpkfams_shared_adapscaff.tab") or die;
printf O ("%s\n", join("\t", qw(hpkfamilypair proteinpair sharedelements familypair timesfamiliescompared) ) );
foreach $fam_pair (keys %hpk_fam_sharing){
  foreach $pk_pair (keys %{$hpk_fam_sharing{$fam_pair}}){
    printf O ("%s\n", join("\t", $fam_pair, $pk_pair, @{$hpk_fam_sharing{$fam_pair}{$pk_pair}}));
  }
}
close(O);
###############################





##############################
####### SUBROUTINES ##########
##############################

##############################
sub collect_kinase_adaptorsscaffolds_data{
  my ($pk);
  my (@fields, @tmp);
  my (%hpk_fams, %pk_adaptorscaffold, %hpkfam_data);
  
  ##############################
  ## Loading HPKs classification and HPKs per family
  foreach (File2Array("/home/malonso/phd/kinome/hpk/531_hpkd_G_F_SF_N_ID_ACcanon_ACisof_COORDs.tab")){
    @fields = splittab($_);
    if($fields[3] !~ /\~/ && $fields[4] ne "NA"){
      push(@{$hpk_fams{join("_", @fields[0..1])}}, $fields[5]); ## {pkfam}=[ACs]
    }
  }
  ##############################

  ##############################
  ## Loading adaptors/substrates of each HPK.
  ## Loading SIF file and retrieving 1st neighbours
  foreach (File2Array("/home/malonso/phd/kinome/scaffolds_interactome3D_interactome/pin_backgrounds/subs_5_interactome_neighb/computing_statsignif_of_pAS.pl.new.0.01.tab",1)){
    ##  fam pk  pk_subs subs_partner  is_pk_AS  freq  pvalue
    @fields = splittab($_);
    push(@{$pk_adaptorscaffold{$fields[1]}}, $fields[3]);
  }
  ##############################
  
  ##############################
  ## Collecting data per family
  foreach my $fam (keys %hpk_fams){
    foreach my $pk ( @{$hpk_fams{$fam}} ){
      if(exists $pk_adaptorscaffold{$pk}){
        $hpkfam_data{$fam}{$pk}=[@{$pk_adaptorscaffold{$pk}}];
      }
    }
  }
  ##############################
  
  return (\%hpkfam_data, \%pk_adaptorscaffold);
}
##############################
