# created on: 17/Mar/2011 by M.Alonso
#
# USAGE:
#   PERL5LIB env variable:
#    update PERL5LIB variable in .bashrc
#    export PERL5LIB=${PERL5LIB}:/home/malonso/phd/kinome/scripts/modules/
#
# CALLING MODULE
#   use SIFTSTools;
#   
#   About SIFTS.
#   SIFTS is a joint project between UniProt and PDBe and provides an 
#   up-to-date resource for residue level mapping between UniProt and PDB entries.
#   The resource also provides further residue level annotation from the
#   IntEnz, GO, Pfam, InterPro, SCOP, CATH and Pubmed databases.
#   The information is released every week at the same time as the release
#   of new PDB entries and is widely used by databases such as RCSB, PDBSum,
#   Pfam, SCOP, Interpro, and DAS server providers.
#   http://www.ebi.ac.uk/pdbe/docs/sifts/
#   
#   

use strict;
use warnings;
use LoadFile;

require Exporter;
package SIFTSTools;

our @ISA       = qw(Exporter);
our @EXPORT    = qw( 
                    load_pdb_chain_pfam_UNIPROTAC_PDBID_pdbchains
                    );    # Symbols to be exported by default
#


##############################
######## SUBROUTINES ######### 
##############################

##############################
### Loads the file pdb_chain_pfam.lst into a hash
### {ac}{pdbid}=[chainids]
### 
### PDB	CHAIN	SP_PRIMARY	PFAM_ID
### 101m	A	P02185	PF00042
### 102l	A	P00720	PF00959
### 
sub load_pdb_chain_pfam_UNIPROTAC_PDBID_pdbchains{
  
  my @fields;
  my %return_hash; ### {ac}{pdbid}=[chainids]
  
  foreach (LoadFile::File2Array("/aloy/home/malonso/phd_proj_dbs/sift_pdbmappings/pdb_chain_pfam.lst",1)){
    @fields = LoadFile::splittab($_);
    push(@{$return_hash{$fields[2]}{$fields[0]}},$fields[1]);
  }
  
  return \%return_hash;
}
##############################
