#!/usr/bin/env perl
#
# script for  mapping Kinome Ids to UniRef100 Ids via Uniprot ACs
#
# Kinome Ids -> Uniprot AC  -> UniRef100
#
# 
#
use strict;
use warnings;

my (%pk_ac,%ac_uniref,%pk_uniref);

## loading hash PKcom=>seq from file Human_kinase_protein.fasta Kinase.com
## mapping_HumanPK.com_to_Uniprot201005.txt COMES FROM THE MAPPING OF HPKcom FILE DONE WITH MOSCA'S SCRIPT VS UNIPROT_2010-05
#==> mapping_HumanPK.com_to_Uniprot201005.txt <==
#PAK3_Hsap  O75914-2
#LATS2_Hsap Q9NRM7
#Wee1B_Hsap P0C1S8
open(F,$ARGV[0]) or die; # mapping_HumanPK.com_to_Uniprot201005.txt
my @F =<F>;
chomp(@F);
foreach (@F){
  my ($pk,$ac) = split("\t",$_);
  $pk_ac{$pk}=$ac;
}
undef @F;
close(F);

# uniref_mapping_result_C4BC.tab COMES FROM MAPPING mapping_HumanPK.com_to_Uniprot201005.txt_ACs IN UNIREF100
##==> uniref_mapping_result_C4BC.tab <==
##From To
##Q6FI27 UniRef100_P49841
##Q5U0E6 UniRef100_Q5U0E6
##B0LPF1 UniRef100_P17948
open(F,$ARGV[1]) or die; # uniref_mapping_result_C4BC.tab
@F =<F>;
chomp(@F);
foreach (@F){
  my ($ac,$uniref) = split("\t",$_);
  $ac_uniref{$ac}=$uniref;
}
undef @F;
close(F);

## loading hash PKcom from file Human_kinase_protein.fasta Kinase.com
#>TTBK2_Hsap (CK1/TTBK)
#>TTBK1_Hsap (CK1/TTBK)
#>TSSK4_Hsap (CAMK/TSSK)
open(F,$ARGV[2]) or die; # provide file Human_kinase_protein.fasta 
@F =<F>;
chomp(@F);
foreach (@F){
  $pk_uniref{$1}="-" if(/^>(\w+)\s+/);
}
undef @F;
close(F);

foreach my $pk (keys %pk_ac){
  foreach my $ac (keys %ac_uniref){
    if($pk_ac{$pk} eq $ac){ $pk_uniref{$pk}=$ac_uniref{$ac};}
  }
}

print "$_\t$pk_uniref{$_}\n" foreach (keys %pk_uniref);




