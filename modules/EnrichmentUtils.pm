# created on: 17/Mar/2011 by M.Alonso
#
# USAGE:
#   PERL5LIB env variable:
#    update PERL5LIB variable in .bashrc
#    export PERL5LIB=${PERL5LIB}:/home/malonso/phd/kinome/scripts/modules/
#
# CALLING MODULE
#   use ListCompare;
#

use strict;
use warnings;
use Data::Dumper; # print Dumper myDataStruct

use LoadFile;

require Exporter;
package EnrichmentUtils;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(  
                      compute_GO_terms_enrichment
                  );    # Symbols to be exported by default
#

##############################
## Description
##    The function computes GO terms enrichment for a set of human proteins.
##    Several parameters can be set such as the back ground set, the GO categories
##    to be analyzed, the method for multiple testing correction and the 
##    statistical significance threshold.
##    Remember that the target set of proteins must be a subset of the 
##    set used as the background.
## 
## 
## Input:
##  Ref. to hash containing the arguments. The hash must be contain the 
##  following key-values pairs:
##    - targetset => Ref. to array containing the set of target Uniprot ACs (Mandatory)
##    - bgset => Ref. to array containing the set of background Uniprot ACs (Optional. Default, the complete set of human proteins that are GO annotated)
##    - gocats => Ref. to array containing the GO categories on which to conduct the enrichment analysis [ALL | BP | CC | MF] (Optional. Default, ALL)
##    - alpha => Stat. significant threshold for the pvalue of the multiple testing  (Optional. Default, 0.05)
##  e.g.: 
## my %args = (
##            targetset => \@target,
##            bgset => \@bg,
##            gocats => \@gocats,
##            alpha => 0.00001
##            );
## Output:
##  - Ref. to hash of array of arrays (HoAoA) containing data of the enriched terms (if any);
##    {GOCAT}=[[goid, goname, prots_annot_with_enriched_term, enrichment_proportion, raw_pvalue, pvalue_BH, pvalue_Bonf], []]
##  
##  
## Usage:
##    %hoaoa = %{ compute_GO_terms_enrichment(\%args) };
## 
sub compute_GO_terms_enrichment{
  ### Installed Perl Modules
  use Statistics::R;
  use List::MoreUtils qw(uniq);
  use Data::Dumper; # print Dumper myDataStruct
  
  ### Perl Modules by MAAT
  use Logs qw(log2);
  
  ### Load hash containing the arguments.
  my %arguments = %{$_[0]};
  
  ########## Checking input arguments
  my $flag_proteome_as_bg_set=0; ### Flag for notifying that the full proteome will be used as BG set
  my ($outdir, $method, $alpha);
  my (@fields, @target_set, @bg_set, @gocats);
  my @avail_go_cats = qw(ALL BP CC MF);
  my @avail_methods = qw (holm hochberg hommel bonferroni BH BY fdr none);
  
  ### Checking target set.
  if(exists $arguments{'targetset'} && ref($arguments{'targetset'}) eq 'ARRAY'){
    @target_set  = uniq @{$arguments{'targetset'}};
    print "Enrichment analysis. target set: OK.\n";
  }else{ die "Died. Please provide a valid target set. (Must be a ref. to array)\n";}
  
  ### Checking for background set. If not provided, the complete set of
  ### human proteins that are GO annotated will be used as background.
  if(exists $arguments{'bgset'} && ref($arguments{'bgset'}) eq 'ARRAY'){
    @bg_set  = uniq @{$arguments{'bgset'}};
    print "Enrichment analysis. background set: OK.\n";
  }else{
    ### Loading as the BG all human proteins that are GO annotated.
    foreach (LoadFile::File2Array("/aloy/home/malonso/phd_proj_dbs/uniprot/uniprot_2011_11/hs_uniprot_2011_11_AC2GO.map")){
      @fields = LoadFile::splittab();
      push(@bg_set, $fields[0]) if ($fields[1] ne 'NO_GO_TERMS_AVAIL');
    }
    @bg_set= uniq @bg_set;
    $flag_proteome_as_bg_set = 1; ### Notifying that the full proteome will be used as BG set
    print "Enrichment analysis. Loading human proteome as background set: OK.\n";
  }
  
  ### Checking for Go categories to be analyzed for enrichment.
  if(exists $arguments{'gocats'} && ref($arguments{'gocats'}) eq 'ARRAY'){
    @gocats  = uniq @{$arguments{'gocats'}};
    ### Checking for valid Go categories
    foreach my $gocat (@gocats){
      die "Died. Not a valid GO category: $gocat\n" unless ( grep {$gocat eq $_} @avail_go_cats);
    }
    print "Enrichment analysis. GO categories '@gocats': OK.\n";
  }else{
    @gocats = qw(BP CC MF);
    print "Enrichment analysis. GO categories '@gocats': OK.\n";
  }
  
  ### Checking stat. significant threshold (alpha) for the pvalue of the multiple testing 
  if(exists $arguments{'alpha'}){
    $alpha = $arguments{'alpha'};
    print "Enrichment analysis. Stat. significant threshold alpha=$alpha: OK.\n";
  }else{
    $alpha = 0.05;
    print "Enrichment analysis. Stat. significant threshold alpha=$alpha: OK.\n";
  }
  ########## 
  
  ########## Loading annotation data.
  my $gocat_goid_goname_infile = "/aloy/home/malonso/phd_proj_dbs/uniprot/uniprot_2011_11/hs_uniprot_2011_11_AC2GO.map";
  
  my %gocat_proteins; ### {gocat}=[protein]. All balls in the urn for the hypergeometric test.
  my %gocat_goid_goname; ### {gocat}{goid}=name
  my %gocat_goid_proteins; ### {gocat}{goid}=[protein]. White balls in the urn for the hypergeometric test.
  my %gocat_goid_proteins_targetset; ### {gocat}{goid}=[protein]. Balls in the target set.
  
  ### Loading GOCAT->GOTERM->GONAME associations
  print "Enrichment analysis. Loading GOCAT<-GOTERM<-GONAME associations\n";
  %gocat_goid_goname = %{load_gocat_goid_goname($gocat_goid_goname_infile, \@gocats)};
  
  ### Loading proteins to go category associations. This datastructure
  ### contains the sets of all balls in the urn for the hypergeometric test.
  print "Enrichment analysis. Loading GOCAT<-proteins associations\n";
  if($flag_proteome_as_bg_set == 1){ ### Loading the full proteome as bg set.
    %gocat_proteins = %{ load_gocat_proteins_full_proteome($gocat_goid_goname_infile, \@gocats) };
  }else{ ### Loading the provided list of bg proteins.
    %gocat_proteins = %{ load_gocat_proteins($gocat_goid_goname_infile, \@gocats, \@bg_set) };
  }
  
  ### Loading proteins to goterm to gocategory associations. This datastructure
  ### contains the sets of white balls in the urn for the hypergeometric test.
  print "Enrichment analysis. Loading GOCAT<-GOID<-proteins associations\n";
  if($flag_proteome_as_bg_set == 1){ ### Loading the full proteome as bg set.
    %gocat_goid_proteins = %{ load_gocat_goid_proteins_full_proteome($gocat_goid_goname_infile, \@gocats) };
  }else{ ### Loading the provided list of bg proteins.
    %gocat_goid_proteins = %{ load_gocat_goid_proteins($gocat_goid_goname_infile, \@gocats, \@bg_set) };
  }
  
  ### Loading GOCAT<-GOID<-proteins associations in target set.
  %gocat_goid_proteins_targetset = %{ load_gocat_goid_proteins($gocat_goid_goname_infile, \@gocats, \@target_set) };
  ##########
  
  ########## 
  ### Computing the GO terms Enrichments using Hypergeometric test
  print "Enrichment analysis. Computing the GO terms Enrichments using Hypergeometric test\n";
  
  ### Creating R object
  my $R = Statistics::R->new(r_bin => "/usr/bin/R");
  
  ## The names of the following four variables had been assigned 
  ## to be consistent with the documentation of R::phyper function.
  my $q;  ## White balls drawn from the urn.
          ## Proteins drawn from the urn that are annotated under a given
          ## GO term.
  
  my $k;  ## Balls drawn from the urn. 
          ## Proteins in the target set. Sample size.
  
  my $m;  ## White balls in the urn.
          ## Proteins in the background set annotated under a given GO term.
          
  my $n;  ## Black balls in the urn.
          ## Proteins in the background set NOT annotated under a given GO term.
  #
  my $background_size; ### Number of proteins annotated under the current GO Category
  my @enrichment_proportion;
  my %enriched_GO_terms; ### {GOCAT}=[[goid, goname, prots_annot_with_enriched_term, enrichment_proportion, raw_pvalue, pvalue_BH, pvalue_Bonf], []]
  
  
  $k = @target_set;
  
  foreach my $gocat ( keys %gocat_goid_proteins_targetset ){
    my (@goids, @qs, @ms, @ns, @pvalues_raw, @pvalues_adjusted_Bonferroni, @pvalues_adjusted_BH, @enrichment_proportion);
    $background_size = @{$gocat_proteins{$gocat}};
    
    foreach my $goid ( keys %{$gocat_goid_proteins_targetset{$gocat}} ){
      ### White balls drawn from the urn.
      $q = @{$gocat_goid_proteins_targetset{$gocat}{$goid}};
      ### White balls in the urn.
      $m = @{$gocat_goid_proteins{$gocat}{$goid}};
      ### Black balls in the urn.
      $n = $background_size - $m;
      
      push(@goids, $goid);
      
      ### Collecting data for statistical analisis in R
      push(@qs, $q);
      push(@ms, $m);
      push(@ns, $n);
      
      ### Refs: PMCID: PMC2649394, PMC2447756
      push(@enrichment_proportion, sprintf ("%.2f", log2($q/($m*$k/($n+$m)))));
    }
    
    ### Setting variables in R
    $R->set( 'k', $k );
    $R->set( 'qs', \@qs );
    $R->set( 'ms', \@ms );
    $R->set( 'ns', \@ns );
    
    ### Running the tests
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
    for(my $i = 0; $i <= $#goids; $i++){
      if( $pvalues_adjusted_Bonferroni[$i] < $alpha ){
        push(@{$enriched_GO_terms{$gocat}}, [$goids[$i], $gocat_goid_goname{$gocat}{$goids[$i]}, $qs[$i], $enrichment_proportion[$i], $pvalues_raw[$i], $pvalues_adjusted_BH[$i], $pvalues_adjusted_Bonferroni[$i]]);
      }
    }
    ####
  }
  $R->stop();
  
  return \%enriched_GO_terms;
  
}
##############################

##############################
## Description
##  Function for internal use of this module. (Althoug it could also be exported).
##  The function load the GOCat <- GOID <- Proteins associations in a hash of hash of array.
##  
## Input:
##  - Path to file with the associations.
##      A0A183	BP	GO:0031424	keratinization
##      Currently using: /aloy/home/malonso/phd_proj_dbs/uniprot/uniprot_2011_11/hs_uniprot_2011_11_AC2GO.map
##    
## Output:
##  - Ref. to hash of array {gocat}{goid}=[proteins]
##  
## Usage:
##  - %hohoa = %{ load_gocat_goid_proteins(infile, \@gocats, \@bgset) }
## 
sub load_gocat_goid_proteins{
  use List::MoreUtils qw(uniq);
  
  my $infile = $_[0];
  my @GOcats = @{$_[1]};
  my @BGset = @{$_[2]};
  
  my (@fields);
  my %hohoa; ## {gocat}{goid}=goname
  
  foreach (LoadFile::File2Array($infile)){
    ### A0A183	BP	GO:0031424	keratinization
    @fields = LoadFile::splittab();
    next if ($fields[1] eq 'NO_GO_TERMS_AVAIL');
    next unless (grep {$fields[1] eq $_} @GOcats);
    next unless (grep {$fields[0] eq $_} @BGset);
    push(@{$hohoa{$fields[1]}{$fields[2]}}, $fields[0]);
  }
  
  ## Making proteins unique in each GOCAT::GOID category
  foreach my $gocat (keys %hohoa){
    foreach my $goid (keys %{$hohoa{$gocat}} ){
      @{$hohoa{$gocat}{$goid}} = uniq @{$hohoa{$gocat}{$goid}};
    }
  }
  
  return \%hohoa;
}
##############################

##############################
## Description
##  Function for internal use of this module. (Althoug it could also be exported).
##  The function load the GOCat <- GOID <- Proteins associations in a hash of hash of array.
##  For speed considerations, this function will be used exclusively
##  when the bg set is the complete proteome (default option for bg set).
##  
## Input:
##  - Path to file with the associations.
##    A0A183	BP	GO:0031424	keratinization
##    Currently using: /aloy/home/malonso/phd_proj_dbs/uniprot/uniprot_2011_11/hs_uniprot_2011_11_AC2GO.map
##    
## Output:
##  - Ref. to hash of array {gocat}{goid}=[proteins]
##  
## Usage:
##  - %hohoa = %{ load_gocat_goid_proteins_full_proteome(infile, \@gocats) }
## 
sub load_gocat_goid_proteins_full_proteome{
  use List::MoreUtils qw(uniq);
  
  my $infile = $_[0];
  my @GOcats = @{$_[1]};
  
  my (@fields);
  my %hohoa; ## {gocat}{goid}=goname
  
  foreach (LoadFile::File2Array($infile)){
    ### A0A183	BP	GO:0031424	keratinization
    @fields = LoadFile::splittab();
    next if ($fields[1] eq 'NO_GO_TERMS_AVAIL');
    next unless (grep {$fields[1] eq $_} @GOcats);
    push(@{$hohoa{$fields[1]}{$fields[2]}}, $fields[0]);
  }
  
  ## Making proteins unique in each GOCAT::GOID category
  foreach my $gocat (keys %hohoa){
    foreach my $goid (keys %{$hohoa{$gocat}} ){
      @{$hohoa{$gocat}{$goid}} = uniq @{$hohoa{$gocat}{$goid}};
    }
  }
  
  return  \%hohoa;
}
##############################

##############################
## Description
##  Function for internal use of this module. (Althoug it could also be exported).
##  The function load the Proteins -> GOCat associations in a hash of array.
##  
## Input:
##  - Path to file with the associations.
##      A0A183	BP	GO:0031424	keratinization
##      Currently using: /aloy/home/malonso/phd_proj_dbs/uniprot/uniprot_2011_11/hs_uniprot_2011_11_AC2GO.map
##    
## Output:
##  - Ref. to hash of array {gocat}=[proteins]
##  
## Usage:
##  - %hoa = %{ load_gocat_proteins(infile, \@gocats, \@bgset) }
## 
sub load_gocat_proteins{
  use List::MoreUtils qw(uniq);
  
  my $infile = $_[0];
  my @GOcats = @{$_[1]};
  my @BGset = @{$_[2]};
  
  my (@fields);
  my %hoa; ## {gocat}{goid}=goname
  
  foreach (LoadFile::File2Array($infile)){
    ### A0A183	BP	GO:0031424	keratinization
    @fields = LoadFile::splittab();
    next if ($fields[1] eq 'NO_GO_TERMS_AVAIL');
    next unless (grep {$fields[1] eq $_} @GOcats);
    next unless (grep {$fields[0] eq $_} @BGset);
    push(@{$hoa{$fields[1]}}, $fields[0]);
  }
  
  ## Making proteins unique in each GO category
  foreach my $gocat (keys %hoa){
    @{$hoa{$gocat}} = uniq @{$hoa{$gocat}};
  }
  
  return  \%hoa;
}
##############################

##############################
## Description
##  Function for internal use of this module. (Althoug it could also be exported).
##  The function load the Proteins -> GOCat associations in a hash of array.
##  For speed considerations, this function will be used exclusively
##  when the bg set is the complete proteome (default option for bg set).
##  
## Input:
##  - Path to file with the associations.
##    A0A183	BP	GO:0031424	keratinization
##    Currently using: /aloy/home/malonso/phd_proj_dbs/uniprot/uniprot_2011_11/hs_uniprot_2011_11_AC2GO.map
##    
## Output:
##  - Ref. to hash of array {gocat}=[proteins]
##  
## Usage:
##  - %hoa = %{ load_gocat_proteins_full_proteome(infile, \@gocats) }
## 
sub load_gocat_proteins_full_proteome{
  use List::MoreUtils qw(uniq);
  
  my $infile = $_[0];
  my @GOcats = @{$_[1]};
  
  my (@fields);
  my %hoa; ## {gocat}{goid}=goname
  
  foreach (LoadFile::File2Array($infile)){
    ### A0A183	BP	GO:0031424	keratinization
    @fields = LoadFile::splittab();
    next if ($fields[1] eq 'NO_GO_TERMS_AVAIL');
    next unless (grep {$fields[1] eq $_} @GOcats);
    push(@{$hoa{$fields[1]}}, $fields[0]);
  }
  
  ## Making proteins unique in each GO category
  foreach my $gocat ( keys %hoa){
    @{$hoa{$gocat}} = uniq @{$hoa{$gocat}};
  }
  
  return  \%hoa;
}
##############################

##############################
## Description
##  Function for internal use of this module. (Althoug it could also be exported).
##  The function load the GOCAT->GOTERM->GONAME associations in a hash of hash.
##  BP	GO:0031424	keratinization
##  
## Input:
##  - Path to file with the associations.
##    A0A183	BP	GO:0031424	keratinization
##    Currently using: /aloy/home/malonso/phd_proj_dbs/uniprot/uniprot_2011_11/hs_uniprot_2011_11_AC2GO.map
##  - Ref. to array with the GO categories to be taken into account
##  
##  
## Output:
##  - Ref. to hash of hash with the format {gocat}{goid}=goname
##  
## Usage:
##  - %hoh = %{ load_gocat_goid_goname(inputfile, \@gocats) }
## 
sub load_gocat_goid_goname{
  my $infile = $_[0];
  my @GOcats = @{$_[1]};
  
  my (@fields);
  my %hoh; ## {gocat}{goid}=goname
  
  foreach (LoadFile::File2Array($infile)){
    ### A0A183	BP	GO:0031424	keratinization
    @fields = LoadFile::splittab();
    next if ($fields[1] eq 'NO_GO_TERMS_AVAIL');
    $hoh{$fields[1]}{$fields[2]}=$fields[3] if ( grep {$fields[1] eq $_} @GOcats);
  }
  return  \%hoh;
}
##############################


1;
