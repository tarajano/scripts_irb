#!/usr/bin/env perl
#
# created on: 17/Oct/2012 by M.Alonso
#
# Computing PFam domains enrichments in a set of target proteins.
#
# Input:
#   - File(s) from which to collect the background set of Pfam domains.
#   - File containing the target set of proteins on which to compute the 
#     enrichment
#     Note: Both files are the output of PfamScan procedure with format:
#       A7KAX9	PX	8.6e-05	?	132	226	PF00787.17
# 
# Output:
#   - File with the enriched domains in the set of target proteins, format:
#       PfamAC	PfamID	DomainInstances	EnrichmentRatio	pvalue-raw	pvalue-Bonf	pvalue-BH
#       PF08947	BPS	5	4.20	4.571384e-07	6.217082e-05	4.440773e-06
# 
# 
use strict;
use warnings;
use LoadFile;
use List::MoreUtils qw(uniq);
use Statistics::R; 
#use Test::Vars;
use Data::Dumper; # print Dumper myDataStruct


use Logs; ## by MAAT

###############################
### Variables definition
my $background_size;

my (@fields, @tmp, @pfams, @target_set, @enrichment_proportion);

my %pfam2ac; ## {Pfam}=[ACs]
my %ac2pfam; ## {AC}=[Pfams]
my %pfamAC2pfamID; ## {PfamAC}=PfamID
my %pfam_dom_count; ### {PfamAC}=instances

## Data structure for storing the families which set of partners
## are enriched in particular Pfam domains.
my %pfam_dom_enriched; ## {Pfam}=[pvalue_Bonferroni, pvalue_Benjamini-Hochberg]

my %prots_per_Pfamdomain_counts_in_target_set; ## {Pfam_domain}=proteins_with_the_domain
###############################

###############################
print "# Remember to properly set the background and the target sets\n";
###############################

###############################
### Loading the background from the Pfam annotations of substrates and partners.
### Please, check the Pfam annotation files that will be used.

### Files from which to load the background
#my $f1 = "/aloy/home/malonso/phd_proj_dbs/Phospho_DBs_files/integrateddbs/substrates_Pfam_annotation/merged_pfamscan_out.tab";
#my $f2 = "/home/malonso/phd/kinome/scaffolds_interactome3D_interactome/pin_backgrounds/validating_pAS/AS_Pfam_enrichments/pk-partners_Pfam_assignments/merged_pfamscan_out.tab";
#my $f3 = "/home/malonso/phd/kinome/scaffolds/scaffolds_adaptors_among_hpk_interactors/kAS_Pfam_assignments/merged_pfamscan_out.tab";
#my $f4 = "/home/malonso/phd/kinome/scaffolds_interactome3D_interactome/pin_backgrounds/validating_pAS/pAS_Pfam/merged_pfamscan_out.tab";
#push(@tmp, $f1, $f2, $f3, $f4);
my $hs_proteome = "/aloy/home/malonso/phd_proj_dbs/uniprot/uniprot_2011_11/ac2pfam/merged_pfamscan_out.tab";
push(@tmp, $hs_proteome);
###

@tmp = @{ loading_background(\@tmp) };
%ac2pfam = %{$tmp[0]}; ## {AC}=[Pfams]
%pfam2ac = %{$tmp[1]}; ## {Pfam}=[ACs]
%pfamAC2pfamID = %{$tmp[2]}; ## {PfamAC}=PfamID

$background_size=scalar(keys %ac2pfam);
print "# bg_size: ".scalar(keys %ac2pfam)."\n";
###############################

##############################
### Loading the target set of uniprot ACs for which the Pfam domains
### enrichment must be computed.
#my $target_set_infile = "/home/malonso/phd/kinome/scaffolds_interactome3D_interactome/pin_backgrounds/validating_pAS/pAS_Pfam/merged_pfamscan_out.tab";
#my $target_set_infile = "/home/malonso/phd/kinome/scaffolds/scaffolds_adaptors_among_hpk_interactors/kAS_Pfam_assignments/merged_pfamscan_out.tab";
my $target_set_infile = "merged_pfamscan_out.tab";

@target_set = @{ load_target_set($target_set_infile) };
print "# target set size: ".scalar @target_set."\n";
%pfam_dom_count = %{ pfam_domain_instances( $target_set_infile ) };
##############################

##############################
## Computing enrichment pvalue using hypergeometrical test
## and computing the corresponding adjusted pvalues using 
## Bonferroni and Benjamini-Hochberg methods.
##
## Enrichment of Pfam domains in the set of partners of kinase
## families.
##

## The names of the following four variables had been assigned 
## to be consistent with the documentation of R::phyper function.
my $q;  ## Number of partners containing a given domain.
        ## White balls drawn from the urn.

my $k;  ## partners of current kinase family. 
        ## Proteins to be sampled from the proteome.
        ## Sample size. Balls drawn from the urn.

my $m;  ## Proteins in the proteome containing a given domain.
        ## White balls in the urn.
        
my $n;  ## Proteins in the proteome that do not contain a given domain.
        ## Black balls in the urn.
#

my $alpha=0.001;

## Creating R object
my $R = Statistics::R->new(r_bin => "/usr/bin/R");

my (@doms, @qs, @ms, @ns, @pvalues_raw, @pvalues_adjusted_Bonferroni, @pvalues_adjusted_BH);

## Balls drawn from the urn.
$k = @target_set ;

## Passing an arrayref with the set of partners of the family.
%prots_per_Pfamdomain_counts_in_target_set = %{ prots_per_Pfamdomain_counts(\@target_set) };

foreach my $dom (keys %prots_per_Pfamdomain_counts_in_target_set){
  ## White balls drawn from the urn. (Number of drawn proteins that contain at least one instance of the current domain)
  $q = $prots_per_Pfamdomain_counts_in_target_set{$dom};
  ## White balls in the urn. (Number of proteins in the urn that contain at least one instance of the current domain)
  $m = @{$pfam2ac{$dom}};
  ## Black balls in the urn.
  $n = $background_size - $m;
  
  push(@doms, $dom);
  
  ## Collecting data for statistical analisis in R
  push(@qs, $q);
  push(@ms, $m);
  push(@ns, $n);
  
  ## Refs: PMCID: PMC2649394, PMC2447756
  push(@enrichment_proportion, sprintf ("%.2f", log2($q/($m*$k/($n+$m)))));
}

## Setting variables in R
$R->set( 'k', $k );
$R->set( 'qs', \@qs );
$R->set( 'ms', \@ms );
$R->set( 'ns', \@ns );

## Running the tests
$R->run(q`pvalues = phyper( qs - 1, ms, ns, k, lower.tail=FALSE) `);
$R->run(q`pvalues_adjusted_Bonferroni = p.adjust(pvalues, method="bonferroni") `);
$R->run(q`pvalues_adjusted_BH = p.adjust(pvalues, method="BH") `);

####
## Retrieving adjusted pvalues
## If several pvalues are returned, the R->get() function
## returns a ref to an array. Otherwise returns a scalar (not a ref).
## Retrieving raw pvalues
if("ARRAY" eq ref $R->get('pvalues')){
  @pvalues_raw = @{$R->get('pvalues')};
}elsif("" eq ref $R->get('pvalues')){
  @pvalues_raw=();
  push(@pvalues_raw, $R->get('pvalues'));
}
## Retrieving Bonferroni adjusted pvalues
if("ARRAY" eq ref $R->get('pvalues_adjusted_Bonferroni')){
  @pvalues_adjusted_Bonferroni = @{$R->get('pvalues_adjusted_Bonferroni')};
}elsif("" eq ref $R->get('pvalues_adjusted_Bonferroni')){
  @pvalues_adjusted_Bonferroni=();
  push(@pvalues_adjusted_Bonferroni, $R->get('pvalues_adjusted_Bonferroni'));
}
## Retrieving Benjamini-Hochberg adjusted pvalues
if("ARRAY" eq ref $R->get('pvalues_adjusted_BH')){
  @pvalues_adjusted_BH = @{$R->get('pvalues_adjusted_BH')};
}elsif("" eq ref $R->get('pvalues_adjusted_BH')){
  @pvalues_adjusted_BH=();
  push(@pvalues_adjusted_BH, $R->get('pvalues_adjusted_BH'));
}
####

####
## Storing results if they are significant at alpha threshold
## %pfam_dom_enriched{Pfam}=[pvalue_Bonferroni, pvalue_Benjamini-Hochberg]
for(my $i = 0; $i <= $#doms; $i++){
  ### Storing both BH and Bonferroni signif adjpvalues. Remember to un/comment the corresponding printing code
  #if( $pvalues_adjusted_Bonferroni[$i] < $alpha &&  $pvalues_adjusted_BH[$i] < $alpha ){ $pfam_dom_enriched{$doms[$i]}=[ $enrichment_proportion[$i], $pvalues_raw[$i], $pvalues_adjusted_Bonferroni[$i],$pvalues_adjusted_BH[$i]]; }
  ### Storing both BH signif adjpvalues. Remember to un/comment the corresponding printing code
  my $rawpvalue = sprintf("%.2e", $pvalues_raw[$i]);
  my $adjpvalue = sprintf("%.2e", $pvalues_adjusted_BH[$i]);
  if( $pvalues_adjusted_BH[$i] < $alpha ){ $pfam_dom_enriched{$doms[$i]}=[ $enrichment_proportion[$i], $rawpvalue, $adjpvalue]; }
}
  
$R->stop();
##############################

##############################
### Printing out

### Printing both BH and Bonferroni signif adjpvalues
#printf ("%s\n", jointab( qw(PfamAC PfamID DomainInstances EnrichmentRatio pvalue-raw adjpvalue-Bonf adjpvalue-BH) ) );
#foreach my $dom ( sort { $pfam_dom_enriched{$b}[0] <=> $pfam_dom_enriched{$a}[0] } keys %pfam_dom_enriched ){
  #printf ("%s\n", jointab($dom, $pfamAC2pfamID{$dom}, $prots_per_Pfamdomain_counts_in_target_set{$dom}, @{$pfam_dom_enriched{$dom}} ) );
#}

### Printing BH signif adjpvalues
printf ("%s\n", jointab( qw(PfamAC PfamID Proteins DomainInstances EnrichmentRatio pvalue-raw adjpvalue-BH) ) );
foreach my $dom ( sort { $pfam_dom_enriched{$b}[0] <=> $pfam_dom_enriched{$a}[0] } keys %pfam_dom_enriched ){
  printf ("%s\n", jointab($dom, $pfamAC2pfamID{$dom}, $prots_per_Pfamdomain_counts_in_target_set{$dom}, $pfam_dom_count{$dom}, @{$pfam_dom_enriched{$dom}} ) );
}
##############################


##############################
####### SUBROUTINES ##########
##############################

##############################
### Load target set input file.
### 
### Input:
###  Path to a Pfam annotation file 
###   A7KAX9	PX	8.6e-05	?	132	226	PF00787.17
### 
### Returns:
###  Ref. to array containing the ACs in the Pfam annotation file
### 
sub load_target_set{
  my (@fields, @target_set_tmp);
  foreach (File2Array($_[0])){
    ### A7KAX9	PX	8.6e-05	?	132	226	PF00787.17
    @fields = splittab($_);
    push(@target_set_tmp, $fields[0]);
  }
  @target_set_tmp = uniq @target_set_tmp;
  return \@target_set_tmp;
}
##############################


##############################
## Description:
##  Counts how many instances of Pfam domain (Di) exist in the set of
##  target proteins.
## 
## Input:
##  Path to file containing the output of PfamScan
## 
## Returns:
##  Returns a ref_hash: {PfamDom} = instances_count
## 
## Usage:
## %pfam_dom_count = %{ pfam_domain_instances( "/path/to/pfamscan.out.tab" ) };
## 
## 
sub pfam_domain_instances{
  my (@fields);
  my %instances; ### {PfamAC}=instances
  
  foreach (File2Array($_[0])){
    ### A7KAX9	PX	8.6e-05	?	132	226	PF00787.17
    @fields = splittab();
    my ($pfam,$tmp) = splitdot($fields[-1]);
    if(exists $instances{$pfam}){
      $instances{$pfam}+=1;
    }else{
      $instances{$pfam}=1;
    }
  }
  return \%instances;
}
##############################











##############################
## 
## For each Pfam domain (Di) represented in the set of target proteins,
## count how many proteins in set contain at least one instance of Di.
## 
## Returns a ref_hash with Pfam domains as keys (Di) and as values the
## number of proteins in the set that contain at least one copy of Di.
## 
## {PfamDom}=proteins_in_set_with_at_least_one_instance_of_PfamDom
## 
sub prots_per_Pfamdomain_counts{
  use List::MoreUtils qw(uniq);
  my @target_acs = uniq @{$_[0]};
  
  my %counts; ## {Pfam}=target_acs
  
  foreach my $ac (@target_acs){
    ## Skip partners that are not Pfam annotated.
    next unless ( exists $ac2pfam{$ac} && 0 < scalar @{$ac2pfam{$ac}} );
    
    foreach my $pfam_dom ( uniq @{$ac2pfam{$ac}} ){
      #next if ($pfam_dom eq "");
      if(exists $counts{$pfam_dom}){
        $counts{$pfam_dom}++;
      }else{
        $counts{$pfam_dom}=1;
      }
    }
  }
  return \%counts;
  
}
##############################

###############################
### Loading the background from which to compute enrichment of Pfam domains
### 
### For the background:
###   - We are keeping only the Uniprot ACs that have at least one Pfam
###     assignment.
###   - We are 'treating' uniprot isoforms as canonical (might be dangerous).
### 
### Input:
###   Reference to an array containing the paths to Pfam annotation files.
### 
### Returns:
###   Reference to an array containing refereces to three hashes:
###     - Uniprot AC to Pfam AC mapping {uniprotAC}=[pfamAC]
###     - Pfam AC to Uniprot AC mapping {pfamAC}=[uniprotAC]
###     - Pfam AC to Pfam ID mapping {pfamAC}=pfamID
### 
### 
sub loading_background{
  my @infiles = @{$_[0]};
  my ($ac,$tmp,$pfam);
  my (@pfam_annotations, @fields);
  my (%ac2pfam_tmp, %pfam2ac_tmp, %pfamAC2pfamID_tmp);
  
  ### Merging the contents of input files and making entries unique.
  foreach (@infiles){ push(@pfam_annotations, File2Array($_)); }
  @pfam_annotations = uniq(@pfam_annotations);
  
  foreach (@pfam_annotations){
    ## A1L4K2	Pkinase	5.2e-66	?	26	321	PF00069.18
    @fields = splittab($_);
    
    ### Skipp entries (proteins) without Pfam domain assignments
    next unless (defined $fields[1]);
    
    ($ac,$tmp) = splitdash($fields[0]); ### isoforms as canonical
    ($pfam,$tmp) = splitdot($fields[-1]);
    
    ### In cases of proteins with more than one instance of a given domain,
    ### avoid assigning twice the protein to the same domain.
    unless ( grep {$ac eq $_ } @{$pfam2ac_tmp{$pfam}} ){ push (@{$pfam2ac_tmp{$pfam}}, $ac); }
    
    ### In case of AC 2 Pfam assignments, you might want to keep track 
    ### of all instances of a given domain.
    push (@{$ac2pfam_tmp{$ac}}, $pfam);
    
    ## Loading mapping pfamAC -> pfamID
    $pfamAC2pfamID_tmp{$pfam}=$fields[1];
  }
  
  return [\%ac2pfam_tmp, \%pfam2ac_tmp, \%pfamAC2pfamID_tmp];
}
###############################

