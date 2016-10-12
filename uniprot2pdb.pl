#!/usr/bin/env perl 
#
# June 2010
#
# mapping UNIPROT ACs to PDB IDs
# provide to this script:
# argv0: file with a list of uniprotacs or the output file from the script 'exactMatchUniprotSimplifyLabel.py' written by Mosca.
# argv1: http://www.ebi.ac.uk/uniprot/pdb_chain_uniprot.lst
#

use strict;
use warnings;

my %AC_query; my %AC2PDB;  my $pdbid_chain;
my @pdb_chain_uniprot; my @fields;

#############
## Comment the option that will not be used. 
## Do not forget to also comment/uncomment the corresponding PRINT OUT OPTION 
## at the end of the script.


## INPUT OPTION No.1:
## The input file is a list of UniprotACs
## 
#open(F,$ARGV[0])or die; # argv0: file with a list of uniprotacs
#while(<F>){
  #chomp;
  #$AC_query{$_}=1;
#}
#close(F);
#print "...query file loaded\n";


## INPUT OPTION No.2
## When the first input file is the output file from the script 'exactMatchUniprotSimplifyLabel.py' written by Mosca.
## The format of the output of this script is a list of: ID<tab>UniProtAC
##
open(F,$ARGV[0])or die; # argv0: file with a list of uniprotacs
while(<F>){
  chomp;
  @fields=split("\t",$_);
  
  ## Dealing with isoforms.
  ## The pdb_chain_uniprot.lst does not contains mappings to isoforms. In order to map isoforms from the query 
  ## I decided to use the query UniprotAC anyway but eliminating the isoform specification
  $fields[1]=$1 if($fields[1] =~ /(\w{6})-\d+/);
  
  $AC_query{$fields[1]}=$fields[0];
}
close(F);
print "...query file loaded\n";
#############

#############
open(F,$ARGV[1])or die; # argv1: provide file http://www.ebi.ac.uk/uniprot/pdb_chain_uniprot.lst
@pdb_chain_uniprot=<F>;
chomp(@pdb_chain_uniprot);
close(F);
print "...pdb_chain_uniprot.lst file loaded\n";
#############

#############
# mapping the ACs to PDBid_chain
foreach my $AC (sort keys %AC_query){
  print "$AC\n";
  foreach (@pdb_chain_uniprot){
    @fields = split("\t",$_);
    if ($AC eq $fields[2]){
      $pdbid_chain=join("_",@fields[0..1]);
      push(@{$AC2PDB{$AC}},$pdbid_chain);
    }else{
       $AC2PDB{$AC}=[] if(!exists $AC2PDB{$AC});
    }
  }
}
#############

#############
## PRINT OUT OPTION No.1
#open(OUT,">AC2PDB.out")or die;
#print OUT "$_\t@{$AC2PDB{$_}}\n" foreach (sort keys %AC2PDB);
#close(OUT);
##
## PRINT OUT OPTION No.2
open(OUT,">AC2PDB.out")or die;
#print OUT "$AC_query{$_}\t$_\t@{$AC2PDB{$_}}\n" foreach (sort keys %AC2PDB);

foreach my $key (sort keys %AC2PDB){
  foreach my $pdbkey (@{$AC2PDB{$key}}){
    print OUT "$AC_query{$key}\t$key\t$pdbkey\n";
  }
}
close(OUT);
#############
