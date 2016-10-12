# created on: 23/Ago/2011 by M.Alonso
#
# USAGE:
#   PERL5LIB env variable:
#    update PERL5LIB variable in .bashrc
#    export PERL5LIB=${PERL5LIB}:/home/malonso/phd/kinome/scripts/modules/
#
# CALLING MODULE
#   use ParsePDBFile.pm;
# 
# 
# PDB file format: 

use strict;
use warnings;

require Exporter;
package ParsePDBFile;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(  get_HET_records
                      get_pdb_chains_ids
                      get_pdb_chains_ids_by_molid
                      get_RESIDUE_ALL_ATOMS_coordinates
                      get_RESIDUE_SIDECHAIN_atoms_coordinates
                      get_CHAIN_ALL_ATOMS_coordinates
                      ); # Symbols to be exported by default
###

##############################
##  Retrieving all atoms coordinates of a chain.
##  Arguments:
##    1) chain_id of the relevant chain
##    3) reference to an array containing the PDB file
## Returns:
##    1) a reference to a 2D array of x,y,z coordinates per atom.
## 
sub get_CHAIN_ALL_ATOMS_coordinates{
  my $Chain_id = $_[0];
  my @pdbfile = @{$_[1]};
  my @fields;
  my ($ATOM,$chain,$x,$y,$z);
  my $flag=0;
  my @return_coords;
  
  foreach(@pdbfile){
    @fields=split("",$_);
    $ATOM=join("",@fields[0..3]);
    $chain = $fields[21];
    if($ATOM eq "ATOM" && $chain eq $Chain_id){
      $flag++;
      $x = join("",@fields[30..37]); trimspaces($x);
      $y = join("",@fields[38..45]); trimspaces($y);
      $z = join("",@fields[46..53]); trimspaces($z);
      push(@return_coords, [$x,$y,$z]);
    }
    last if($chain ne $Chain_id && $flag>0);
  }
  return \@return_coords;
}
##############################

##############################
##  Retrieving all atoms coordinates of a residue.
##  Argument:
##    1) resnum of the relevant residue
##    2) chain_id of the relevant residue
##    3) reference to an array containing the PDB file
## Returns:
##    1) a reference to a 2D array of x,y,z coordinates per atom.
## 
sub get_RESIDUE_ALL_ATOMS_coordinates{
  my $CatRes_resnum = $_[0];
  my $Chain_id = $_[1];
  my @pdbfile = @{$_[2]};
  my @fields;
  my ($ATOM,$chain,$resnum,$x,$y,$z);
  my $flag=0;
  my @return_coords;
  
  foreach(@pdbfile){
    @fields=split("",$_);
    $ATOM=join("",@fields[0..3]);
    $chain = $fields[21];
    $resnum = join("",@fields[22..25]); trimspaces($resnum);
    if($ATOM eq "ATOM" && $chain eq $Chain_id && $resnum eq $CatRes_resnum){
      $flag++;
      $x = join("",@fields[30..37]); trimspaces($x);
      $y = join("",@fields[38..45]); trimspaces($y);
      $z = join("",@fields[46..53]); trimspaces($z);
      push(@return_coords, [$x,$y,$z]);
    }
    last if($resnum ne $CatRes_resnum && $flag>0);
  }
  return \@return_coords;
}
##############################

##############################
##  Retrieving coordinates of side chain atoms of a residue.
##  Argument:
##    1) resnum of the relevant residue
##    2) chain_id of the relevant residue
##    3) reference to an array containing the PDB file
## Returns:
##    1) a reference to a 2D array of x,y,z coordinates per side chain atom.
## 
sub get_RESIDUE_SIDECHAIN_atoms_coordinates{
  my $CatRes_resnum = $_[0];
  my $Chain_id = $_[1];
  my @pdbfile = @{$_[2]};
  my @fields;
  my ($ATOM,$chain,$resnum,$atom_name,$x,$y,$z);
  my $flag=0;
  my $sidechain_flag=0;
  my @return_coords;
  
  foreach(@pdbfile){
    @fields=split("",$_);
    $ATOM=join("",@fields[0..3]);
    $chain = $fields[21];
    $resnum = join("",@fields[22..25]); trimspaces($resnum);
    $atom_name = join("",@fields[12..15]); trimspaces($atom_name);
    $sidechain_flag=0;
    
    ## Skip if current atoms is a backbone atom.
    foreach my $atom (qw(N CA C O)){
      $sidechain_flag++ if($atom eq $atom_name);
    } next if ($sidechain_flag > 0); 
    
    if($ATOM eq "ATOM" && $chain eq $Chain_id && $resnum eq $CatRes_resnum){
      $flag++;
      $x = join("",@fields[30..37]); trimspaces($x);
      $y = join("",@fields[38..45]); trimspaces($y);
      $z = join("",@fields[46..53]); trimspaces($z);
      push(@return_coords, [$x,$y,$z]);
    }
    last if($resnum ne $CatRes_resnum && $flag>0);
  }
  return \@return_coords;
}
##############################

##############################
## Retrieving the chains ids in current
## PDB file grouped by MOL_ID.
## 
## Argument:
##   1) reference to an array containing the PDB file
## Returns:
##   1) hash of {molid}=>[chains]
## 
sub get_pdb_chains_ids_by_molid{
  my @pdbfile = @{$_[0]};
  chomp(@pdbfile);
  my $compnd_records_flag=0;
  my ($mol_id, $chains);
  my (@chainsids, @fields, @tmp);
  my %moldids_chainsids;

  foreach my $record (@pdbfile){
    @fields=split('\s+', $record);
    
    ## exit foreach IF the last COMPND record has been read
    last if($fields[0] ne "COMPND" && $compnd_records_flag>0);
    
    if($record =~ /COMPND/ && $record =~ /MOL_ID:\s+(\d+);/){
      $compnd_records_flag++;
      $mol_id="mol_id_".$1;
    }elsif($record =~ /COMPND/ && $record =~ /CHAIN:(.+)/){
      $chains=$1;
      $chains =~ s/;|,|\s+//g;
      $moldids_chainsids{$mol_id}=[split("", $chains)];
    }
  }
  return %moldids_chainsids;
}
##############################

##############################
## Retrieving the chains ids in current PDB file
##
## Argument:
##   1) reference to an array containing the PDB file
## Returns:
##   1) an array with the ids of chains in the PDB file
## 
sub get_pdb_chains_ids{
  my @pdbfile = @{$_[0]};
  chomp(@pdbfile);
  my $compnd_records_flag=0;
  my $chains;
  my (@chainsids, @fields, @tmp);

  foreach my $record (@pdbfile){
    @fields=split('\s+', $record);
    
    ## exit foreach IF the last COMPND record has been read
    last if($fields[0] ne "COMPND" && $compnd_records_flag>0);
    
    if($fields[0] eq "COMPND"){
      $compnd_records_flag++;
      if($record =~ /CHAIN:(.+)/){
        $chains=$1;
        $chains =~ s/;|,|\s+//g;
        push(@chainsids,split("", $chains));
      }
    }
  }
  return @chainsids;
}
##############################

##############################
## Retrieving HET records.
## PDB File format HET: (http://structure.usc.edu/pdb/part_37.html)
##
## Argument:
##   1) reference to an array containing the PDB file
## Returns:
##   1) an array of arrays. [[hetID, ChainID, seqNum, iCode, numHetAtoms],[hetID, ChainID, seqNum, iCode, numHetAtoms]]
## 
sub get_HET_records{
  my @pdbfile = @{$_[0]};
  chomp(@pdbfile);

  my $het_records_flag=0;
  my ($hetID, $ChainID, $seqNum, $numHetAtoms);
  my @fields;
  
  ## Array to be returned. [[hetID, ChainID, seqNum, numHetAtoms],[hetID, ChainID, seqNum, numHetAtoms]]
  my @HET_records;

  foreach my $record (@pdbfile){
    @fields=split('\s+', $record);
    
    ## exit foreach IF the last HET record has been read
    last if($fields[0] ne "HET" && $het_records_flag>0);
    
    if($fields[0] eq "HET"){
      $het_records_flag++;
      @fields=split("", $record);
      ($hetID, $ChainID, $seqNum, $numHetAtoms)=(join("",@fields[7..9]),$fields[12],join("",@fields[13..16]),join("",@fields[20..24]));
      trimspaces($hetID);
      trimspaces($seqNum);
      trimspaces($numHetAtoms);
      push(@HET_records,[$hetID, $ChainID, $seqNum, $numHetAtoms]);
    }
  }#printf (" %d\n", scalar(@HET_records));
  return @HET_records;
}
##############################

##############################
## Removing all spaces from a string.
## Will modify the argument given.
## usage:
## trimspaces($string);
sub trimspaces{
  $_[0] =~ s/\s+//g;
  return;
}
##############################


1;
