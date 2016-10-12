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
package ScaffoldsUtils;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(  
                      load_gold_std_set_kas2pk_association
                      load_gold_std_set_pk2kas_association
                      
                      load_as2kinase_association
                      
                      load_as2kinase_association
                      load_kinase2as_association
                      
                      load_kAS2PK_association
                      load_PK2kAS_association
                      load_pAS2PK_association
                      
                      load_rAS2PK_association
                      load_PK2rAS_association
                      
                      );    # Symbols to be exported by default
# load_bg_distributions() to be finished

##############################
### Description
###  Load kinase to kAS associations.
###  Uses the Gold Std. Set of PK-kAS pairs
###  
### Usage:
###  %pks2kas_gss = %{ load_gold_std_set_pk2kas_association() }
###   
### Input:
###   - None
### 
### Returns:
###   - Ref. to hash containing PK to kAS associations {kas}=[pks]
###   
sub load_gold_std_set_pk2kas_association{
  my $infile = '/home/malonso/phd/kinome/scaffolds/kAS_GoldStandardSet/pks_kas_gold_standard_set.tab';
  my @fields;
  my %hash; ### {kas}=[pks]
  
  print "Loading Gold Std Set kinases to kAS associations\n";
  foreach (LoadFile::File2Array($infile, 1)){
    ### pk kAS
    @fields = LoadFile::splittab();
    push(@{$hash{$fields[1]}}, $fields[0]);
  }
  return \%hash;
}
##############################

##############################
### Description
###  Load kAS to kinase associations.
###  Uses the Gold Std. Set of PK-kAS pairs
###  
### Usage:
###  %kas2pk_gss = %{ load_gold_std_set_kas2pk_association() }
###   
### Input:
###   - None
### 
### Returns:
###   - Ref. to hash containing kAS to PK associations {pk}=[kASs]
###   
sub load_gold_std_set_kas2pk_association{
  my $infile = '/home/malonso/phd/kinome/scaffolds/kAS_GoldStandardSet/pks_kas_gold_standard_set.tab';
  my @fields;
  my %hash; ### {pk}=[kASs]
  
  print "Loading Gold Std Set kAS to kinase associations\n";
  foreach (LoadFile::File2Array($infile, 1)){
    ### pk kAS
    @fields = LoadFile::splittab();
    push(@{$hash{$fields[0]}}, $fields[1]);
  }
  return \%hash;
}
##############################


##############################
### Description
###  Load kinase to rAS associations.
###  Only rAS known to have binary PPI with kinases are considered.
###  rAS: are the potential adaptor/scaffolds identified by Ramírez F, Albrecht M. Trends Cell Biol. 2010 Jan;20(1)
###  
### Usage:
###  %pk2rAS = %{ load_PK2rAS_association() }
###   
### Input:
###   - None
### 
### Returns:
###   - Ref. to hash containing kinase to rAS associations {rAS}=[kASs]
###   
sub load_PK2rAS_association{
  my $infile = "/home/malonso/phd/kinome/scaffolds/scaffolds_adaptors_Ramirez_et_al/pk2rAS_assoc.tab";
  my @fields;
  my %hash; ### {pk}=[AS]
  
  print "Loading rAS to kinase associations\n";
  foreach (LoadFile::File2Array($infile, 1)){
    ### pk rAS
    @fields = LoadFile::splittab();
    push(@{$hash{$fields[1]}}, $fields[0]);
  }
  
  return \%hash;
}
##############################

##############################
### Description
###  Load rAS to kinase associations.
###  Only rAS known to have binary PPI with kinases are considered.
###  rAS: are the potential adaptor/scaffolds identified by Ramírez F, Albrecht M. Trends Cell Biol. 2010 Jan;20(1)
###  
### Usage:
###  %rAS2pk = %{ load_rAS2PK_association() }
###   
### Input:
###   - None
### 
### Returns:
###   - Ref. to hash containing rAS to kinase associations {kAS}=[rASs]
###   
sub load_rAS2PK_association{
  my $infile = "/home/malonso/phd/kinome/scaffolds/scaffolds_adaptors_Ramirez_et_al/pk2rAS_assoc.tab";
  my @fields;
  my %hash; ### {pk}=[AS]
  
  print "Loading rAS to kinase associations\n";
  foreach (LoadFile::File2Array($infile, 1)){
    ### pk rAS
    @fields = LoadFile::splittab();
    push(@{$hash{$fields[0]}}, $fields[1]);
  }
  
  return \%hash;
}
##############################

##############################
### Description
###  Load kAS to kinase associations.
###  kAS are the ones that are known to have binary PPI with kinases.
###  
###  
### Usage:
###  %pk2kAS = %{ load_PK2kAS_association(path_to_file_with_kAS2PK_associations) }
###   
### Input:
###   - Path to file with the pAS to Kinase associations
###     /home/malonso/phd/kinome/scaffolds/scaffolds_adaptors_among_hpk_interactors/as_pks_bin_pin/scaffolds_adaptors_binary_hpk_interactors.tab
###   
### Returns:
###   - Ref. to hash containing kinase to kAS associations {kAS}=[PKs]
###   
sub load_PK2kAS_association{
  my $infile = $_[0] || die "Please, provide a path to the file with the pAS to Kinase associations";
  my @fields;
  my %hash; ### {pk}=[AS]
  
  print "Loading PK to kAS associations\n";
  foreach (LoadFile::File2Array($infile, 1)){
    ### fam	pk	pk_subs	subs_partner	is_pk_AS	freq	pvalue
    @fields = LoadFile::splittab();
    push(@{$hash{$fields[3]}}, $fields[2]);
  }
  
  return \%hash;
}
##############################

##############################
### Description
###  Load pAS to kinase associations.
###  
### Usage:
###  %hash = %{ load_pAS2PK_association(path_to_file_with_kAS2PK_associations) }
###   
### Input:
###   - Path to file with the pAS to Kinase association
###   
### Returns:
###   - Ref. to hash containing pAS to kinase associations {pk}=[pAS]
###   
sub load_pAS2PK_association{
  
  my $input_file = $_[0];
  my @fields;
  my %pk_pAS_assignments;
  print "Loading pAS to PK associations\n";
  
  foreach my $line (LoadFile::File2Array($input_file,1)){
    ## fam   pk   pk_subs   subs_partner   is_pk_AS   freq   pvalue
    @fields = LoadFile::splittab($line);
    push(@{ $pk_pAS_assignments{$fields[1]} }, $fields[3]);
  }
  return(\%pk_pAS_assignments);
}
##############################


##############################
### Description
###  Load kAS to kinase associations.
###  kAS are the ones that are known to have binary PPI with kinases.
###  
###  
### Usage:
###  %pAS2Kin = %{ load_kAS2PK_association(path_to_file_with_kAS2PK_associations) }
###   
### Input:
###   - Path to file with the kAS to Kinase associations
###     /home/malonso/phd/kinome/scaffolds/scaffolds_adaptors_among_hpk_interactors/as_pks_bin_pin/scaffolds_adaptors_binary_hpk_interactors.tab
###   
###   
### Returns:
###   - Ref. to hash containing pAS to kinase associations {pk}=[kAS]
###   
sub load_kAS2PK_association{
  my $infile = $_[0];
  my @fields;
  my %hash; ### {pk}=[AS]
  
  print "Loading kAS to PK associations\n";
  foreach (LoadFile::File2Array($infile, 1)){
    ### fam	pk	pk_subs	subs_partner	is_pk_AS	freq	pvalue
    @fields = LoadFile::splittab();
    push(@{$hash{$fields[2]}}, $fields[3]);
  }
  
  return \%hash;
}
##############################


##############################
### Description
###   Retrieves the kinases associated to each known adaptors/scaffold
###  
### Usage:
###   %hash = %{ load_kinase2as_association(path_to_kAS_to_kinase_file) }
###   
### Input:
### 
### Returns:
###   A ref to a hash {as}=[pk, pk, pk]
###   Uniprot ACs are the protein identifiers used.
###   
sub load_kinase2as_association{
  my (@fields);
  my %hash;
  my $infile = $_[0] || "/home/malonso/phd/kinome/scaffolds/scaffolds_adaptors_among_hpk_interactors/scaffolds_adaptors_among_hpk_interactors.pl.cleaned.tab.acs";
  foreach (LoadFile::File2Array($infile, 1)){
    ### fam   pk-ID   pk-AC   pk_adp-scaf-AC    pk_adp-scaf-ID    pk_adp-scaf_type
    @fields = LoadFile::splittab();
    push(@{$hash{$fields[3]}}, $fields[2]);
  }
  return \%hash;
}
##############################


##############################
### Description
###   Retrieves the known adaptors/scaffolds associated to each HPK
###  
### Usage:
###   %hash = %{ load_as2kinase_association(path_to_kAS_to_kinase_file) }
###   
### Input:
### 
### Returns:
###   A ref to a hash {pk}=[as, as, as]
###   Uniprot ACs are the protein identifiers used.
###   
###   
sub load_as2kinase_association{
  my (@fields);
  my %hash;
  my $infile = $_[0] || "/home/malonso/phd/kinome/scaffolds/scaffolds_adaptors_among_hpk_interactors/scaffolds_adaptors_among_hpk_interactors.pl.cleaned.tab.acs";
  foreach (LoadFile::File2Array($infile, 1)){
    ### fam   pk-ID   pk-AC   pk_adp-scaf-AC    pk_adp-scaf-ID    pk_adp-scaf_type
    @fields = LoadFile::splittab();
    push(@{$hash{$fields[2]}}, $fields[3]);
  }
  return \%hash;
}
##############################


##############################
### Load background distributions
### 
###
### 
### load_bg_distributions("/home/malonso/phd/kinome/scaffolds_interactome3D_interactome/pin_backgrounds/subs_5_interactome_neighb/dists/")
### 

sub load_bg_distributions{
  my @paths_to_files = </home/malonso/phd/kinome/scaffolds_interactome3D_interactome/pin_backgrounds/subs_5_interactome_neighb/dists/*.dist>;
  my ($subs_num, $file_extension);
  my (@tmp,@file, @file_content);
  my %hash_bg;
  
  foreach my $paths_to_file (@paths_to_files){
    @tmp = split('/', $paths_to_file);
    ($subs_num, $file_extension) = split('\.', $tmp[-1]);
    @file_content=();
    @file = LoadFile::File2Array($paths_to_file);
    foreach my $line (@file){
      push(@file_content, split(" ", $line));
    }
    @{$hash_bg{$subs_num}}=@file_content;
  }
  return \%hash_bg;
}
##############################


1;
