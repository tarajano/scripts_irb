#!/usr/bin/env perl
#
# created on: 02/Dec/2011 at 15:06 by M.Alonso
#
#
# This script is for counting the the number of shared substrates and
# PPI partners for pairs of kinases within kinases families.
#
# Output file: whithin_hpkfams_shared_partners_shared_substrates.tab
#
# The output file can be used for generating the corresponding
# lattice xplot by using the R script:
# within_hpkfams_shared_partners_shared_substrates.r
#
# The output file can also be used for computing the correlations coeffs.
# (Pearson, Spearman) and their corresponding pvalues by using the 
# script:
# compute_Pearson_Spearman_pvalues.pl
#
#

use strict;
use warnings;
use LoadFile;
use List::MoreUtils qw(uniq);
use List::Compare qw(get_intersection);

my ($pk, $subs, $partners, $overlap);

my (@fields,@overlap);

my %tmp;

my (%hpks_class,%pk_subs,%pk_ppis,%hpk_fams,%map_pkAC2fam);
my %hash; ## {uniprotID}=[$partners-$overlap, $overlap, $subs-$overlap, summation]

my %hpkfam_data; ## {pkfam}{pk}=[[ppis ACs],[subs ACs]]
my %hpkfam_shared_ppi_subs; ## {pkfam}{pk1-pk2}=[shared_ppi, shared_subs]

##############################
## Loading HPKs classification and HPKs per family
foreach (File2Array("/home/malonso/phd/kinome/hpk/531_hpkd_G_F_SF_N_ID_ACcanon_ACisof_COORDs.tab")){
  @fields = splittab($_);
  if($fields[3] !~ /\~/ && $fields[4] ne "NA"){
    $hpks_class{$fields[5]}=[@fields[0..4]]; ## {AC}=[G F SF NAME UniprotID]
    push(@{$hpk_fams{join("_", @fields[0..1])}}, $fields[5]); ## {pkfam}=[ACs]
    $map_pkAC2fam{$fields[5]}=join("_", @fields[0..1]);
  }
}
##############################

##############################
# Loading known substrates for each HPK.
# Treating isoforms ACs as canonical.
foreach(File2Array("/home/malonso/phd/kinome/hpk/working_on_phosphoDBs/integratedphosphodb_genpssm/integratedphosphodb_pevents_per_pk.tab")){
  @fields = splittab($_);
  $pk = $fields[0];
  @fields = splitdash($fields[1]);
  $subs = $fields[0];
  ## Storing substrates per HPK
  push(@{$pk_subs{$pk}}, $subs);
}
## Making substrates uniq for each PK.
foreach(keys %pk_subs){
  @fields = uniq(@{$pk_subs{$_}});
  @{$pk_subs{$_}}=@fields;
}
##############################

##############################
## Loading PPI partners of each HPK.
## Supply the path to the sif files with partners of kinases.
my @sif_files = </aloy/scratch/malonso/hpk_ppidb_201111/hpks_sif_files/*.neighb>;
my @tmp;
foreach my $file (@sif_files){
  ## Next if file is empty (i.e. no PPI partners available).
  next if (-z $file);
  
  @fields = split("/", $file);
  @fields = splitdot($fields[-1]);
  $pk = $fields[0];
  ## Loading SIF file and retrieving 1st neighbours
  foreach my $ppi_pair (File2Array($file)){
    @fields = splittab($ppi_pair);
    ## Storing 1st neighbors for PK as well as for PKFams
    if($fields[0] eq $pk){
      ## Treating isoforms ACs as canonical.
      @tmp = splitdash($fields[1]);
      push(@{$pk_ppis{$pk}}, $tmp[0]);
    }elsif($fields[1] eq $pk){
      ## Treating isoforms ACs as canonical.
      @tmp = splitdash($fields[0]);
      push(@{$pk_ppis{$pk}}, $tmp[0]);
    }
  }
}
## Making partners uniq for each PK.
foreach(keys %pk_ppis){
  @fields = uniq(@{$pk_ppis{$_}});
  @{$pk_ppis{$_}}=@fields;
}
##############################

###############################
### Eliminating from the list of substrates
### those that are already known to be partners.
#%tmp =%{substrates_complement(\%pk_subs)};
#%pk_subs = %tmp;
###############################

###############################
### Eliminating from the list of partners
### those that are already known as substrates.
%tmp =%{partners_complement(\%pk_ppis)};
%pk_ppis = %tmp;
###############################

##############################
## Collecting data per family
foreach my $fam (keys %hpk_fams){
  ## Skipping families with less than 4 members. Usless for correlation analysis.
  next if (4>scalar(@{$hpk_fams{$fam}}));
  
  foreach my $pk ( @{$hpk_fams{$fam}} ){
    if(exists $pk_subs{$pk} && exists $pk_ppis{$pk}){
      $hpkfam_data{$fam}{$pk}=[\@{$pk_ppis{$pk}},\@{$pk_subs{$pk}}];
    }
  }
}

## Deleting families with less than 4 members avaliable for comparisons.
foreach my $fam (keys %hpkfam_data){
  delete $hpkfam_data{$fam} if ( 4>scalar( keys %{$hpkfam_data{$fam}} ) );
}
##############################

##############################
## Computing shared partners and shared substrates between every pair
## of kinases within a family.
my ($pk1, $pk2, $shared_partners, $shared_substrates, $list_compare);
my (@pk1_acs, @pk2_acs);

foreach my $fam (sort {$a cmp $b} keys %hpkfam_data){
  my @pks_in_fam = keys %{$hpkfam_data{$fam}};
  
  ## Pairwise comparison of shared PPI partners and shared substrates
  ## among HPKs.
  for(my $i=0; $i<$#pks_in_fam; $i++){
    #print  "$fam $pks_in_fam[$i]\n";
    for(my $ii = $i+1; $ii<=$#pks_in_fam; $ii++){
      $pk1=$pks_in_fam[$i];
      $pk2=$pks_in_fam[$ii];
      
      ## Fetching PPI partners of current PK pair
      @pk1_acs = @{$hpkfam_data{$fam}{$pk1}[0]}; ## PK1 PPI partners
      @pk2_acs = @{$hpkfam_data{$fam}{$pk2}[0]}; ## PK2 PPI partners
      ## Computing the intersection (shared partners)
      $list_compare = List::Compare->new('--unsorted', '--accelerated',\@pk1_acs, \@pk2_acs);
      $shared_partners = scalar($list_compare->get_intersection);
      
      ## Fetching substrates of current PK pair
      @pk1_acs = @{$hpkfam_data{$fam}{$pk1}[1]}; ## PK1 substrates
      @pk2_acs = @{$hpkfam_data{$fam}{$pk2}[1]}; ## PK2 substrates
      ## Computing the intersection (shared substrates)
      $list_compare = List::Compare->new('--unsorted', '--accelerated',\@pk1_acs, \@pk2_acs);
      $shared_substrates = scalar($list_compare->get_intersection);
      
      ## Saving data only if shared_partners > 0 AND shared_substrates > 0
      $hpkfam_shared_ppi_subs{$fam}{join("_", $pk1,$pk2)}=[$shared_partners,$shared_substrates] if($shared_partners>0 && $shared_substrates>0);
    }
  }
}
## Deleting families with less than 6 kinase pairs compared.
foreach my $fam (keys %hpkfam_shared_ppi_subs){
  delete $hpkfam_shared_ppi_subs{$fam} if ( 6>scalar( keys %{$hpkfam_shared_ppi_subs{$fam}} ) );
}
##############################

##############################
### Printing to data file
open(O,">within_hpkfams_shared_partners_shared_substrates_ppiscompl.tab") or die;
printf O ("%s\n", join("\t", qw(hpkfamily sharedpartners sharedsubstrates) ) );
foreach my $fam (sort {$a cmp $b} keys %hpkfam_shared_ppi_subs){
  foreach my $pkpair (keys %{$hpkfam_shared_ppi_subs{$fam}} ){
    printf O ("%s\n", join("\t", $fam, @{$hpkfam_shared_ppi_subs{$fam}{$pkpair}}) );
  }
}
close(O);
##############################



##############################
######## SUBROUTINES #########
##############################

##############################
## Eliminating from the list of substrates
## those that are already known as partners.
sub substrates_complement{
  my %old_pk_subs = %{$_[0]};
  my %new_pk_subs;
  my $list_compare;
  my @subs_complement;
  
  foreach my $pk (keys %old_pk_subs){
    if(exists $pk_ppis{$pk}){
      $list_compare = List::Compare->new('--unsorted', '--accelerated',\@{$pk_ppis{$pk}}, \@{$old_pk_subs{$pk}});
      @subs_complement = $list_compare->get_complement(); ## Get those items which appear (at least once) only in the second list.
      $new_pk_subs{$pk}=[@subs_complement];
    }else{
      $new_pk_subs{$pk}=$old_pk_subs{$pk};
    }
  }
  
  return \%new_pk_subs;
}
##############################

##############################
## Eliminating from the list of partners
## those that are already known as substrates.
sub partners_complement{
  my %old_pk_ppi = %{$_[0]};
  my %new_pk_ppi;
  my $list_compare;
  my @ppi_complement;
  
  foreach my $pk (keys %old_pk_ppi){
    if(exists $pk_subs{$pk}){
      $list_compare = List::Compare->new('--unsorted', '--accelerated',\@{$pk_subs{$pk}}, \@{$old_pk_ppi{$pk}});
      @ppi_complement = $list_compare->get_complement(); ## Get those items which appear (at least once) only in the second list.
      $new_pk_ppi{$pk}=[@ppi_complement];
    }else{
      $new_pk_ppi{$pk}=$old_pk_ppi{$pk};
    }
  }
  
  return \%new_pk_ppi;
}
##############################



