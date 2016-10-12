#!/usr/bin/env perl
#
# created on: 10/Feb/2011 by M.Alonso
#



use strict;
use warnings;

###########################
## http://www.ebi.ac.uk/msd-srv/msdchem/cgi-bin/cgi.pl?APPLICATION=1
## http://www.ccp4.ac.uk/html/pdbformat.html
#AMSE M SELENOMETHIONINE
#APTR Y O-PHOSPHOTYROSINE
#ASCS C 3-(ethyldisulfanyl)-L-alanine    
#BMSE M SELENOMETHIONINE
#BPTR Y O-PHOSPHOTYROSINE
#BSCS C 3-(ethyldisulfanyl)-L-alanine    
#BTPO T PHOSPHOTHREONINE
#CAS C   S-(DIMETHYLARSENIC)CYSTEINE
#CME C S,S-(2-HYDROXYETHYL)THIOCYSTEINE
#CSD C 3-SULFINOALANINE
#CSW C CYSTEINE-S-DIOXIDE
#CY0 C S-{3-[(4-ANILINOQUINAZOLIN-6-YL)AMINO]-3-OXOPROPYL}-L-CYSTEINE
#KCX K LYSINE NZ-CARBOXYLIC ACID
#MHO M S-OXYMETHIONINE
#MSE M SELENOMETHIONINE
#PTR Y O-PHOSPHOTYROSINE
#SCS C 3-(ethyldisulfanyl)-L-alanine     
#SEP S PHOSPHOSERINE
#TPO T PHOSPHOTHREONINE
####
#A   A ADENOSINE-5-MONOPHOSPHATE
#D   No results
#I   I   INOSINIC ACID
####################
my %atyp_aa_subst=(
                MSE=>"MET", MHO=>'MET',
                SCS=>'ALA', CSD=>'ALA', 
                PTR=>'TYR', TPO=>'THR',
                CAS=>'CYS', CME=>'CYS', CSW=>'CYS', CY0=>'CYS',
                KCX=>'LYS', SEP=>'SER');
###########################



#my $r3ds_path = "/home/malonso/phd/kinome/hpk/hpkdoms/hpkd_SI95QC95/strs/";



#####
open(I,"list.list") or die;
my @pdbfiles=<I>;
chomp(@pdbfiles);
close(I);


foreach (@pdbfiles){
  my @newpdb = atyp_aa_subst($_);
  
  $_ =~ s/\.pdb//;
  my $newpdb = $_."_noptms.pdb";
  open(O,">$newpdb") or die;
  print O "$_\n" foreach(@newpdb);
  close(O);
}


###########################
##### SUBROUTINES #########
###########################

###########################
## http://deposit.rcsb.org/adit/docs/pdb_atom_format.html

sub atyp_aa_subst{
  my (@pdb,@newpdb);
  open(I, $_[0]) or die;
  @pdb = <I>;
  chomp(@pdb);
  close(I) or die;

=cut
HETATM 4694  N   MSE A 767      -0.255   2.656 -39.366  1.00 58.91           N  
HETATM 4695  CA AMSE A 767       0.735   2.692 -38.280  0.50 58.17           C  
HETATM 4696  CA BMSE A 767       0.600   2.688 -38.188  0.50 57.87           C  
HETATM 4697  C   MSE A 767       0.964   4.085 -37.697  1.00 54.06           C  
HETATM 4698  O   MSE A 767       1.319   4.243 -36.534  1.00 49.54           O 
=cut 
  
  foreach my $record (@pdb){
    my @record =split('',$record);
    my $recordname = join('',@record[0..2]);
    
    if ($recordname eq "HET"){ # if HETATM
      my $new_record;
      my $resname = join('',@record[17..19]); # fetch resname ALA,MET,etc
      my $atomname = join('',@record[13..14]); # fetch atmname N,CA,O,etc
      
      if($atomname eq "N " || $atomname eq "CA" || $atomname eq "C " || $atomname eq "O "){
        $new_record="ATOM  ".join('',@record[6..15])." ".$atyp_aa_subst{$resname}.join('',@record[20..$#record]);
        #print "$new_record\n";
        push (@newpdb,$new_record);
      }
    }else{
      push (@newpdb,$record);
    }
  }
  
  return @newpdb;
 
}
###########################













