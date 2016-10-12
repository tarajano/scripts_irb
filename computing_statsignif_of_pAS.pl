#!/usr/bin/env perl
#
# created on: 30/Mar/2012 by M.Alonso
# 
# 
# Computing the statistical significance of potential Adaptor/Scaffolds shared by kinases substrates.
# 
# Input:
#   - Files with the distributions of freqs. of potential A/S among substrates of a given kinase.
#   - 
# 
# 


use strict;
use warnings;
use Statistics::R;
use Data::Dumper; # print Dumper myDataStruct
#use List::MoreUtils qw(uniq);


use LoadFile;
use HPKsUtils qw(hpk_classification load_pk_substrates);
use DBServer;

my ($fam, $pk, $substrate, $partner, $interactor, $freq);

my $min_number_of_substrates_per_kinase = 5; 


## Loading R interface
#my $R = Statistics::R->new(r_bin => "/usr/bin/R");

my (@tmp, @fields, @partners, @substrates, @pin_partners, @bg_distribution, @scaffolds_adaptors);


my %tmp;
my %hpk_fams; ## {pkfam}=[ACs]

my (%hpks_substrates) ; ## {pk}=[ACs]
my %hpk_class; ## {ac}=[g,f,sf,ac,id]
my %fam_pk_subs_pin;  ## {fam}{pk}{substrate}=[partners]
my %subs_partner_freq; ## {fam}{pk}{partner}=freq
my %pk_known_scaffolds_adaptors; ## {pk}=[ACs]

## This data structure contains the different random backgrounds
## generated for each range of the "number of substrates" (e.g. 5_7).
my %bg_distributions; ## {range}=[statistics].


##############################
## 
print "Loading kinase substrates\n";

## {ac}=[g,f,sf,ac,id]
%hpk_class = %{ hpk_classification() };

## Loading HPKs substrates.
## {pk}=[ACs]
%tmp = %{ load_pk_substrates() };

## Classifying kinases into families.
## {fam}{pk}=[substrates]
%hpks_substrates = %{ kinase_to_family(\%hpk_class,\%tmp) };
##############################

##############################
## Loading background distributions
## {range}=[statistics] {5_7}=[statistic].
print "Loading background distributions\n";

## Remember to set the path to the proper files
#  /home/malonso/phd/kinome/scaffolds/ptck_q_0905/scheme3/intersection_size/randbgs/dists_substrates_interactome/dists/*.dist";
# /home/malonso/phd/kinome/scaffolds_interactome3D_interactome/pin_backgrounds/subs_5_interactome_neighb/dists/*.dist
%bg_distributions = %{ load_bg_distributions("/aloy/home/malonso/tmp/full_Hs_PIN_bg/dists/") };
#print Dumper %bg_distributions;
##############################

##############################
## Loading known scaffolds and adaptors
print "Loading known scaffolds and adaptors\n";

foreach(File2Array("/home/malonso/phd/kinome/scaffolds/scaffolds_adaptors_among_hpk_interactors/scaffolds_adaptors_among_hpk_interactors.pl.cleaned.tab.acs",1)){
  ## fam  pk-ID pk-AC pk_adp-scaf-AC  pk_adp-scaf-ID  pk_adp-scaf_type
  @fields = splittab($_);
  push (@{$pk_known_scaffolds_adaptors{$fields[2]}}, $fields[3]);
  push (@tmp, $fields[2]);
}
@scaffolds_adaptors = uniq(@tmp);
@tmp=();
##############################

##############################
## Retrieving kinase substrates PPI partners
print "Retrieving kinase substrates PPI partners\n";
## Connecting to ppidb_2011_11 database
my $conn = connect2db("ppidb_2011_11","ppi_select","ppi");
## {fam}{pk}{substrate}=[partners]
%fam_pk_subs_pin = %{ retrieving_substrates_ppi_partners()  };
# Disconnecting from ppidb_2011_11 database
$conn->disconnect();
##############################

##############################
## Compute frequencies for 
## substrates partners. 
## {fam}{pk}{subs_partner}=freq
print "Compute frequencies of substrates partners\n";
%subs_partner_freq = %{ compute_substrate_partners_freq( \%fam_pk_subs_pin ) };
##############################

##############################
## Evaluate stat. significance
## of partners frequencies.
print "Evaluate stat. significance of partners frequencies.\n";
my ($substrates, $bg_set, $pvalue, $subs_partner, $is_known_AS);

open(O,">$0.new.tab") or die;
printf O ("%s\n", jointab( qw(fam pk pk_subs subs_partner is_pk_AS freq pvalue) ));
foreach $fam (sort keys %subs_partner_freq){
  foreach $pk (sort keys %{$subs_partner_freq{$fam}} ){
    foreach $subs_partner (sort keys %{$subs_partner_freq{$fam}{$pk}}){
      next if ($subs_partner eq $pk);
      $is_known_AS="no";
      
      ## Checking if current subs_partner is a known A/S of curren kinase
      if( grep {$subs_partner eq $_} @{$pk_known_scaffolds_adaptors{$pk}} ) { $is_known_AS="yes"; }
      
      $substrates = scalar keys %{$fam_pk_subs_pin{$fam}{$pk}};
      
      ### Checking enought substrates are known for the kinase and if also checking if the number of
      ### substrates is in our set of backgrounds.
      next unless ($substrates > $min_number_of_substrates_per_kinase && exists $bg_distributions{$substrates});
      
      $freq = $subs_partner_freq{$fam}{$pk}{$subs_partner};
      $pvalue = extreme_value_analysis($freq, $substrates);
      printf O ("%s\n", jointab($fam, $pk, $substrates, $subs_partner, $is_known_AS, $freq, $pvalue)) if($pvalue < 0.01);
    }
  }
}
close(O);
##############################


##############################
######## SUBROUTINES #########
##############################

##############################
## Computes the upper probability
## (pvalue) of a "frequency"
## in a distribution.
## Returns a pvalue.
##
sub extreme_value_analysis{
  my $frequency = $_[0];
  my $bg_set = $_[1];
  my $ge_freq=0; ## Number of values greater of equal than frequency in the BGdist.
  my $pvalue;
  my $bg_len = scalar @{$bg_distributions{$bg_set}} or die print "subs_num $bg_set\n";
  
  foreach (@{$bg_distributions{$bg_set}}){
    $ge_freq++ if($_ >= $frequency);
  }
  $pvalue = sprintf("%.5f", $ge_freq/$bg_len) ;
  return $pvalue;
}
##############################

##############################
## Retrieving kinase substrates
## PPI partners.
sub retrieving_substrates_ppi_partners{

  my $fams = scalar keys %hpks_substrates;
  my $count=1;
  my ($fam, $pk, $substrate);
  my %fam_pk_subs_pin;
  
  foreach $fam (keys %hpks_substrates){
    ## {fam}{pk}=[substrates, partners]
    
    print "Fam $fam $count of $fams\n";
    $count++;
    
    foreach $pk (keys %{$hpks_substrates{$fam}}){
      
      my @substrates = @{$hpks_substrates{$fam}{$pk}};
      
      ## Skip if the number of substrates known for current kinase
      ## is below the tshreshold.
      next if ($min_number_of_substrates_per_kinase > scalar @substrates);
      
      ## Retrievin PIN partners of substrates
      foreach $substrate (@substrates){
        ## Skip self interactions
        next if ($substrate eq $pk);
        
        ## Retrieving PIN partners of current substrate
        my @pin_partners = @{ querying_ppidb($substrate) };
        
        ## Skip if no PIN partners were found.
        next if (1>scalar(@pin_partners));
        
        ## {fam}{pk}{substrate}=partners
        @{$fam_pk_subs_pin{$fam}{$pk}{$substrate}} = @pin_partners;
      }
    }
  }
  ## {fam}{pk}{substrate}=partners
  return \%fam_pk_subs_pin;
}
##############################

##############################
## Computing the frequency of
## Substrates-Pi interactions.
## For each kinase, we compute
## the number of its substrates
## that interacts with Pi.
## Pi is a PPI partner of any 
## of the substrates of the current
## kinase.
##
## returns: {fam}{pk}{partner}=freq
## 
sub compute_substrate_partners_freq{
  my ($fam, $pk, $sub);
  my @partners;
  my %subs_partner_freq; # {fam}{pk}{partner}=freq
  my %fam_pk_subs_pin = %{$_[0]};
  
  foreach $fam (keys %fam_pk_subs_pin){
    foreach $pk (keys %{$fam_pk_subs_pin{$fam}}){
      foreach $sub (keys %{$fam_pk_subs_pin{$fam}{$pk}}){
        next if ($pk eq $sub);
        @partners = @{ $fam_pk_subs_pin{$fam}{$pk}{$sub} };
        foreach (@partners){
          if(exists $subs_partner_freq{$fam}{$pk}{$_}){$subs_partner_freq{$fam}{$pk}{$_}++;}
          else{$subs_partner_freq{$fam}{$pk}{$_}=1;}
        }
      }
    }
  }
  return \%subs_partner_freq;
}
##############################

##############################
sub load_bg_distributions{
  my $path = $_[0];
  my ($subs_num, $file_extension);
  my (@tmp,@file, @file_content, @paths_to_files);
  my %hash_bg;
  
  opendir (DIR, $path) or die;
  while (my $file = readdir(DIR)) { push(@paths_to_files, $path.$file); }
  close(DIR);
  
  foreach my $paths_to_file (@paths_to_files){
    @tmp = split('/', $paths_to_file);
    next if ($tmp[-1] =~ /^\./ );
    ($subs_num, $file_extension) = split('\.', $tmp[-1]);
    @file_content=();
    @file = File2Array($paths_to_file);
    foreach my $line (@file){
      push(@file_content, split(" ", $line));
    }
    @{$hash_bg{$subs_num}}=@file_content;
  }
  return \%hash_bg;
}
##############################

##############################
## Querying for PPIs
sub querying_ppidb{
  my $queryAC = $_[0];
  my @pin_partners;
  my @row;
  my %tmp;
  
  ## Selecting all interactions for current PK partner
  my $DBquery = $conn->prepare(
  "SELECT uniref_canonical1, uniref_canonical2 ".
  "FROM ppidb_interactions ".
  "WHERE (uniref_canonical1=? OR uniref_canonical2=?) AND ".
  "uniprot_taxid1='9606' AND uniprot_taxid2='9606' AND ".
  "NOT no_additional_information AND ".
  "(method_binary OR curation_binary) AND ".
  "active_uniprot_proteins=TRUE AND ".
  "NOT ambiguous_mapping AND ".
  "NOT duplicated_in_author_inferences"
  ) or die;
  
  ## Look for PPIs of the current target
  $DBquery->execute($queryAC, $queryAC) or die $conn->errstr;
  
  while (@row = $DBquery->fetchrow_array()){
    return \@pin_partners if(1>@row);
    $tmp{$row[0]}=1;
    $tmp{$row[1]}=1;
  }
  
  ## Removing self-interactions
  delete $tmp{$queryAC} if (exists $tmp{$queryAC});
  
  @pin_partners = keys %tmp;
  
  return \@pin_partners;
}
##############################

##############################
sub kinase_to_family{
  my %kin_classif = %{$_[0]}; ## kianses classif {ac}=[g,fam,subfam,ac,id]
  my %kin_data = %{$_[1]}; ## kinases data
  my %return_hash;
  my ($pk, $fam) ;
  
  foreach $pk (keys %kin_data) {
    if( exists $kin_classif{$pk} ){
      $fam = joinunderscore( $kin_classif{$pk}[0], $kin_classif{$pk}[1] );
      $return_hash{$fam}{$pk}=$kin_data{$pk};
    }
  }
  ## {fam}{kin}=[acs]
  return \%return_hash;
}
##############################





