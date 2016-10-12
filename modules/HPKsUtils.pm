# created on: 24/01/2012 by M.Alonso
#
# USAGE:
#   PERL5LIB env variable:
#    update PERL5LIB variable in .bashrc
#    export PERL5LIB=${PERL5LIB}:/home/malonso/phd/kinome/scripts/modules/
#
# CALLING MODULE
#   use HPKsUtils;
#

use strict;
use warnings;
use List::MoreUtils qw(uniq);

use LoadFile;

require Exporter;
package HPKsUtils;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(  hpk_classification
                      hpks_per_fam
                      
                      loading_hpks_interactors
                      load_pk_substrates
                      load_pk_substrates_as_hoh
                      load_pk_partners
                      load_pk_partners_exclude_self_interactions
                      
                      load_hs_protein_bin_partners
                      
                      substrates_complement
                      partners_complement
                      
                      canonical_subs_per_hpk
                      isoform_subs_per_hpk
                      
                      load_Pfam_annotations
                      
                      load_triplets
                      load_triplets_to_hash
                      
                      hpk_catalytic_specificity
                      );    # Symbols to be exported by default
#


##############################
###  Retrieves (via DB query) the binary ppi partners for the query ACs.
###  
### Usage:
###  %hash = %{ load_hs_protein_bin_partners( \@queryACs) }
### 
### Input:
###  - A ref. to an array containing the query ACs (canonical)
###  - Human PPI binary interaction data is retrieved from the local DB hs_bin_ppi
### 
### Returns:
###  - A ref. to hash {queryAC}=[PPIpartners]
### 
### 
sub load_hs_protein_bin_partners{
  use DBServer;
  use List::MoreUtils qw(uniq);
  
  my @queryACs = @{$_[0]};
  
  my($conn, $query, $queryac, $ac1, $ac2);
  my (@row);
  my %ac_ppipartners;
  
  $conn = DBServer::connect2localhostdb('hs_bin_ppi');
  $query = $conn->prepare('SELECT uniref_canonical1, uniref_canonical2 FROM bin_ppi WHERE uniref_canonical1=? OR uniref_canonical2=? ') or die $conn->errstr;
  
  foreach $queryac (@queryACs){
    #print "Querying hs_bin_ppi DB for $queryac\n";
    $query->execute($queryac, $queryac) or die $conn->errstr;

    ### Fetchign query results
    while(@row = $query->fetchrow_array()){
      
      ### Checking if no PPI was found for current queryAC
      if(0 == scalar(@row)){
        ### Assign empty array if no PPI was found
        @{$ac_ppipartners{$queryac}}=();
      }else{
        ($ac1, $ac2) = @row;
        ### Checking for self-interactions
        if($ac1 eq $ac2){
          push(@{$ac_ppipartners{$queryac}}, $queryac);
        ### Assigning PPI partners
        }else{
          if($ac1 eq $queryac){ push(@{$ac_ppipartners{$queryac}}, $ac2); }
          elsif($ac2 eq $queryac){ push(@{$ac_ppipartners{$queryac}}, $ac1); }
        }
      }
    }
    
  }
  $query->finish();
  $conn->disconnect();
  
  return \%ac_ppipartners;
}
##############################

##############################
### Description here
###   Retrieves the catalytic specificity (S/T, Y or DS) of kinases.
### 
### Usage:
###   %hash = %{ hpk_catspecif(/home/malonso/phd/kinome/hpk/ec2hpk/map_ec2uniprot.out) }
###   {AC} = stpk | ypk | dspk | inact
### 
### Input file:
###   /home/malonso/phd/kinome/hpk/ec2hpk/map_ec2uniprot.out
### 
### Output:
### 
sub hpk_catalytic_specificity{
  my ($pk_ac, $catspecif);
  my(@fields);
  my %pkac2catspecif;
  
  foreach (LoadFile::File2Array("/home/malonso/phd/kinome/hpk/ec2hpk/map_ec2uniprot.out",1)){
    # pkuniprotid	pkname	pkuniprotac	ec	catspecif	uniprotdescription
    # AAK1_HUMAN	AAK1	Q2M2I8	2.7.11.1	stpk	DE: Non-specific serine/threonine protein kinase. AN: Protein phosphokinase.
    @fields = LoadFile::splittab($_);
    if(defined $fields[4]){
      $catspecif = $fields[4];
      @fields = LoadFile::splitdash($fields[2]);
      $pk_ac = $fields[0];
      $pkac2catspecif{$pk_ac}=$catspecif;
    }else{
      @fields = LoadFile::splitdash($fields[2]);
      $pk_ac = $fields[0];
      $pkac2catspecif{$pk_ac}="inact";
    }
  }
  return \%pkac2catspecif;
}

##############################


##############################
### Description here
### 
### Collects triplets to a hash with keys kins, adps, subs.
### 
### Usage:
###   %hash = %{load_triplets(pathtofile)}
### 
### Input file format:
###   CPLX  Kinase  Adap/Scaff Substrate
###   GOCC  GO terms of subcellular co-localization
###   DDKA  Evidences of domain-domain (DD) interactions between the kinase (K) andthe adaptor/scaffold (A) (3did)
###   DDAS  Evidences of domain-domain (DD) interactions between the adaptor/scaffold (A) and the substrate (S) (3did)
###   //     End of entry
### 
### Output:
###   Reference to hash containing
###   {"kins"}=@kinsACs;
###   {"adps"}=@adpsACs;
###   {"subs"}=@subsACs;
###   
sub load_triplets_to_hash{
  my $infile = $_[0];
  my (@fields, @triplets, @kins, @adps, @subs);
  my %return_hash; ### {pk | adps | subs} = [ ACs ]
  
  foreach(LoadFile::File2Array($infile)){
    @fields = LoadFile::splittab($_);
    push(@triplets, [@fields[1..3]]) if($fields[0] eq "CPLX");
  }
  
  foreach  ( @triplets ){
    push(@kins, ${$_}[0]);
    push(@adps, ${$_}[1]);
    push(@subs, ${$_}[2]);
    #print "${$_}[0] ${$_}[1] ${$_}[2]\n";
  }
  @{$return_hash{"kins"}}=@kins;
  @{$return_hash{"adps"}}=@adps;
  @{$return_hash{"subs"}}=@subs;
  
  return \%return_hash;
}
##############################



##############################
### Description here
### 
### Collects triplets to an array of arrays.
### 
### Usage:
###   @a = @{load_triplets(pathtofile)}
### 
### Input file format:
###   CPLX  Kinase  Adap/Scaff Substrate
###   GOCC  GO terms of subcellular co-localization
###   DDKA  Evidences of domain-domain (DD) interactions between the kinase (K) andthe adaptor/scaffold (A) (3did)
###   DDAS  Evidences of domain-domain (DD) interactions between the adaptor/scaffold (A) and the substrate (S) (3did)
###   //     End of entry
### 
### Output:
###   [ [PK AS SUB], [PK AS SUB], [PK AS SUB] ]
###   
###   
sub load_triplets{
  my $infile = $_[0];
  my (@fields, @triplets);
  
  foreach(LoadFile::File2Array($infile)){
    @fields = LoadFile::splittab($_);
    push(@triplets, [@fields[1..3]]) if($fields[0] eq "CPLX");
  }
  return \@triplets;
}
##############################

##############################
### Loading Pfam annotations
### 
### Usage:
### %myh = %{ load_Pfam_annotations(inputfile) }
### 
### Input file format:
### A7MCY6
### O00151  LIM 4.4e-10 ? 260 314 PF00412.15
### O00459  SH2 5.7e-20 ? 622 696 PF00017.17
### 
### Returns:
### A reference to a hash.
### {O00459}{SH2}=[5.7e-20 ? 622 696 PF00017.17]
### 
sub load_Pfam_annotations{
  my $file = $_[0];
  my @fields;
  my %pfam_assignments;
  
  foreach my $line ( LoadFile::File2Array($file,1)){
    ## O00151	LIM	4.4e-10	?	260	314	PF00412.15
    @fields = LoadFile::splittab($line);
    next unless (defined $fields[1]); ## Skip if there is no Pfam assignment for the current protein
    ## Multiple instances of the same domain are stored
    if(exists $pfam_assignments{$fields[0]}{$fields[1]}){ push( @{ $pfam_assignments{$fields[0]}{$fields[1]} } , @fields[2..$#fields] ); }
    else{ @{ $pfam_assignments{$fields[0]}{$fields[1]} } = @fields[2..$#fields]; }
    
  }
  return(\%pfam_assignments);
}
##############################

###############################
#### Loading Kinases to pAS associations
#### returns a reference to:
####   {PK}{kAS}=""
#sub load_PK_kAS_associations{
  #print "Loading PK to kAS associations\n";
  #my $input_file = "/home/malonso/phd/kinome/scaffolds/scaffolds_adaptors_among_hpk_interactors/scaffolds_adaptors_among_hpk_interactors.pl.cleaned.tab.acs";
  #my @fields;
  #my %pk_kAS_assignments;
  
  #foreach my $line (LoadFile::File2Array($input_file,1)){
    ### AGC_AKT  AKT1  P31749  O14492  SH2B2 adapter
    #@fields = LoadFile::splittab($line);
    #$pk_kAS_assignments{$fields[2]}{$fields[3]}="";
  #}
  #return(\%pk_kAS_assignments);
#}
###############################

###############################
#### Loading Kinases to pAS associations
#### returns a reference to:
####   {PK}{pAS}=""
#sub load_PK_pAS_associations{
  #print "Loading PK to pAS associations\n";
  #my $input_file = "/home/malonso/phd/kinome/scaffolds_interactome3D_interactome/pin_backgrounds/subs_5_interactome_neighb/computing_statsignif_of_pAS.pl.new.0.01.tab";
  #my @fields;
  #my %pk_pAS_assignments;
  
  #foreach my $line (LoadFile::File2Array($input_file,1)){
    ### AGC_AKT  P31749  119 P00519  no  17  0.00020
    #@fields = LoadFile::splittab($line);
    #$pk_pAS_assignments{$fields[1]}{$fields[3]}="";
  #}
  #return(\%pk_pAS_assignments);
#}
###############################

##############################
## Loading kinases interactors.
## {fam}{pk}=[interactors]
sub loading_hpks_interactors{
  
  my (@fields, @tmp);
  my (%pk_interactors, %hpks_per_fam, %hpks_interactors);
  
  ## Loading PPI partners for each HPK.
  #my @sif_files = </home/malonso/phd/kinome/hpk/hpk_ppidb_201111/hpks_sif_files/*.neighb>;
  my @sif_files = </home/malonso/phd/kinome/scaffolds_interactome3D_interactome/hpks_ppis/ppi_files/*.ppi>;
  
  foreach my $file (@sif_files){
    ## Next if file is empty (i.e. no PPI partners available).
    next if (-z $file);
    @fields = split("/", $file);
    @fields = LoadFile::splitdot($fields[-1]);
    my $pk = $fields[0];
    ## Loading SIF file and retrieving 1st neighbours
    foreach my $ppi_pair (LoadFile::File2Array($file)){
      @fields = LoadFile::splittab($ppi_pair);
      ## Storing 1st neighbors for PK as well as for PKFams
      if($fields[0] eq $pk){
        ## Treating isoforms ACs as canonical.
        @tmp = LoadFile::splitdash($fields[1]);
        push(@{$pk_interactors{$pk}}, $tmp[0]);
      }elsif($fields[1] eq $pk){
        ## Treating isoforms ACs as canonical.
        @tmp = LoadFile::splitdash($fields[0]);
        push(@{$pk_interactors{$pk}}, $tmp[0]);
      }
    }
  }
  
  ## Loading known substrates for each HPK.
  foreach(LoadFile::File2Array("/home/malonso/phd/kinome/hpk/working_on_phosphoDBs/integratedphosphodb_genpssm/integratedphosphodb_pevents_per_pk.tab")){
    @fields = LoadFile::splittab($_);
    my $pk = $fields[0];
    ## Treating isoforms ACs as canonical.
    @fields = LoadFile::splitdash($fields[1]);
    ## Storing substrates per HPK
    push(@{$pk_interactors{$pk}}, $fields[0]);
  }
  
  %hpks_per_fam = %{HPKsUtils::hpks_per_fam()};
  
  ## Collecting data per family
  foreach my $fam (keys %hpks_per_fam){
    foreach my $pk ( @{$hpks_per_fam{$fam}} ){
      if(exists $pk_interactors{$pk}){
        @tmp = List::MoreUtils::uniq( @{$pk_interactors{$pk}} );
        @{$hpks_interactors{$fam}{$pk}} = @tmp;
      }
    }
  }
  ## {fam}{pk}=[interactors]
  return \%hpks_interactors;
}
##############################


##############################
## Loading HPKs classification and HPKs per family
## {pkfam}=[ACs]
sub hpks_per_fam{
  my %hash_hpk_fams;
  my @fields;
  foreach (LoadFile::File2Array("/home/malonso/phd/kinome/hpk/531_hpkd_G_F_SF_N_ID_ACcanon_ACisof_COORDs.tab")){
    @fields = LoadFile::splittab($_);
    if($fields[3] !~ /\~/ && $fields[4] ne "NA"){
      push(@{$hash_hpk_fams{join("_", @fields[0..1])}}, $fields[5]); ## {pkfam}=[ACs]
    }
  }
  ## {pkfam}=[ACs]
  return \%hash_hpk_fams;
}
##############################
##############################
## Loading (unique canonical) PPI partners of each HPK.
## Supply the path to the sif files with partners of kinases.
## USAGE:
## %pk_ppis = %{load_pk_partners()}; ## {ac}=[ACs]
##
sub load_pk_partners_exclude_self_interactions{
  my @sif_files = </home/malonso/phd/kinome/scaffolds_interactome3D_interactome/hpks_ppis/ppi_files/*.ppi>;
  my $pk;
  my (@fields, @tmp);
  my %pk_ppis;
  
  foreach my $file (@sif_files){
    ## Next if file is empty (i.e. no PPI partners available).
    next if (-z $file);
    
    @fields = split("/", $file);
    @fields = LoadFile::splitdot($fields[-1]);
    $pk = $fields[0];
    ## Loading SIF file and retrieving 1st neighbours
    foreach my $ppi_pair (LoadFile::File2Array($file)){
      @fields = LoadFile::splittab($ppi_pair);
      ## Treating isoforms ACs as canonical and storing 1st neighbors
      if($fields[0] eq $pk){ @tmp = LoadFile::splitdash($fields[1]); }
      elsif($fields[1] eq $pk){ @tmp = LoadFile::splitdash($fields[0]);}
      push(@{$pk_ppis{$pk}}, $tmp[0]);
    }
  }
  ## Making partners uniq for each PK.
  foreach(keys %pk_ppis){
    @fields = List::MoreUtils::uniq(@{$pk_ppis{$_}});
    @{$pk_ppis{$_}} = grep {$_ ne 'a'} @fields;
  }
  return \%pk_ppis;
}
##############################

##############################
## Loading (unique canonical) PPI partners of each HPK.
## Supply the path to the sif files with partners of kinases.
## USAGE:
## %pk_ppis = %{load_pk_partners()}; ## {ac}=[ACs]
##
sub load_pk_partners{
  my @sif_files = </home/malonso/phd/kinome/scaffolds_interactome3D_interactome/hpks_ppis/ppi_files/*.ppi>;
  my $pk;
  my (@fields, @tmp);
  my %pk_ppis;
  
  foreach my $file (@sif_files){
    ## Next if file is empty (i.e. no PPI partners available).
    next if (-z $file);
    
    @fields = split("/", $file);
    @fields = LoadFile::splitdot($fields[-1]);
    $pk = $fields[0];
    ## Loading SIF file and retrieving 1st neighbours
    foreach my $ppi_pair (LoadFile::File2Array($file)){
      @fields = LoadFile::splittab($ppi_pair);
      ## Treating isoforms ACs as canonical and storing 1st neighbors
      if($fields[0] eq $pk){ @tmp = LoadFile::splitdash($fields[1]); }
      elsif($fields[1] eq $pk){ @tmp = LoadFile::splitdash($fields[0]);}
      push(@{$pk_ppis{$pk}}, $tmp[0]);
    }
  }
  ## Making partners uniq for each PK.
  foreach(keys %pk_ppis){
    @fields = List::MoreUtils::uniq(@{$pk_ppis{$_}});
    @{$pk_ppis{$_}}=@fields;
  }
  return \%pk_ppis;
}
##############################

##############################
## Loading known (unique canonical) substrates for each HPK.
## Treating isoforms ACs as canonical.
## USAGE:
## %pk_subs = %{load_pk_substrates()}; ## {ac}=[ACs]
## 
sub load_pk_substrates{
  my ($pk, $subs);
  my @fields;
  my %pk_subs;
  foreach(LoadFile::File2Array("/home/malonso/phd/kinome/hpk/working_on_phosphoDBs/integratedphosphodb_genpssm/integratedphosphodb_pevents_per_pk.tab")){
    @fields = LoadFile::splittab($_);
    $pk = $fields[0];
    $subs = $fields[1];
    
    ## Treating isoforms ACs as canonical.
    @fields = LoadFile::splitdash($subs);
    $subs = $fields[0];
    
    ## Storing substrates per HPK
    push(@{$pk_subs{$pk}}, $subs);
  }
  ## Making substrates uniq for each PK.
  foreach(keys %pk_subs){
    @fields = List::MoreUtils::uniq(@{$pk_subs{$_}});
    @{$pk_subs{$_}}=@fields;
  }
  return \%pk_subs;
}
##############################

##############################
## Loading substrates for each HPK.
## USAGE:
## %pk_subs = %{load_pk_substrates()}; ## {pkAC}{subsAC}=()
## 
sub load_pk_substrates_as_hoh{
  my ($pk, $subs);
  my @fields;
  my %pk_subs;
  foreach(LoadFile::File2Array("/home/malonso/phd/kinome/hpk/working_on_phosphoDBs/integratedphosphodb_genpssm/integratedphosphodb_pevents_per_pk.tab")){
    @fields = LoadFile::splittab($_);
    $pk = $fields[0];
    
    ## Treating isoforms ACs as canonical.
    @fields = LoadFile::splitdash($fields[1]); $subs = $fields[0];
    #$subs = $fields[1];
    
    ## Storing substrates per HPK
    $pk_subs{$pk}{$subs}=();
  }
  return \%pk_subs;
}
##############################


##############################
## Eliminating from the list of substrates
## those that are already known as partners.
## USAGE:
## %tmp =%{substrates_complement(\%pk_subs, \%pk_ppis)};
## %pk_subs = %tmp;
sub substrates_complement{
  my %old_pk_subs = %{$_[0]};
  my %pk_ppis = %{$_[1]};
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
## USAGE:
## %tmp =%{partners_complement(\%pk_ppis, \%pk_subs)};
## %pk_ppis = %tmp;
sub partners_complement{
  my %old_pk_ppi = %{$_[0]};
  my %pk_subs = %{$_[1]};
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

##############################
## Loading substrates per kinase.
## Treating ACs as canonical and removing duplicate ACs.
## Output:
## A reference to a hash: {pkAC}=[subsCanonicalACs]
sub canonical_subs_per_hpk{
  my ($pk,$subs);
  my @fields;
  my %pk_subs;
  
  foreach(LoadFile::File2Array("/home/malonso/phd/kinome/hpk/working_on_phosphoDBs/integratedphosphodb_genpssm/integratedphosphodb_pevents_per_pk.tab")){
    @fields = LoadFile::splittab($_);
    $pk = $fields[0];
    ## Treating isoforms ACs as canonical.
    @fields = LoadFile::splitdash($fields[1]);
    $subs = $fields[0];
    ## Storing substrates per HPK
    push(@{$pk_subs{$pk}}, $subs);
  }
  ## Making substrates uniq for each PK.
  foreach(keys %pk_subs){
    @fields = uniq(@{$pk_subs{$_}});
    @{$pk_subs{$_}}=@fields;
  }
  return \%pk_subs;
}
##############################

##############################
## Loading substrates per kinase.
## Consider both canonical and isoforms ACs.
## Removing duplicate ACs.
## Output:
## A reference to a hash: {pkAC}=[subsIsoformsACs]
sub isoform_subs_per_hpk{
  my ($pk,$subs);
  my @fields;
  my %pk_subs;
  
  foreach(LoadFile::File2Array("/home/malonso/phd/kinome/hpk/working_on_phosphoDBs/integratedphosphodb_genpssm/integratedphosphodb_pevents_per_pk.tab")){
    @fields = LoadFile::splittab($_);
    $pk = $fields[0];
    $subs = $fields[1];
    ## Storing substrates per HPK
    push(@{$pk_subs{$pk}}, $subs);
  }
  ## Making substrates uniq for each PK.
  foreach(keys %pk_subs){
    @fields = List::MoreUtils::uniq(@{$pk_subs{$_}});
    @{$pk_subs{$_}}=@fields;
  }
  return \%pk_subs;
}
##############################


##############################
## Loading HPKs classification
## Returns a reference to a hash: {pkAC}=[G F SF N ID AC AC-isof Coord]
sub hpk_classification{
  my (@fields);
  my %hpks_class;
  foreach (LoadFile::File2Array("/home/malonso/phd/kinome/hpk/531_hpkd_G_F_SF_N_ID_ACcanon_ACisof_COORDs.tab")){
    @fields = LoadFile::splittab($_);
    if($fields[3] !~ /\~/ && $fields[4] ne "NA"){
      $hpks_class{$fields[5]}=[@fields]; ## {AC}=[G F SF NAME UniprotID]
    }
  }
  return \%hpks_class;
}
##############################


1;
