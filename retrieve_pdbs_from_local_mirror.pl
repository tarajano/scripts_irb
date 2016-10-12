#!/usr/bin/env perl
#
# created on: 22/Aug/2011 by M.Alonso
#
# Retrieving a list of PDB files from the local PDB mirror.
#
#
#

use strict;
use warnings;
use LoadFile;
use File::Copy;

my $pdbid;

## Folder where pdb files will be stored
my $store_folder="/aloy/home/malonso/phd_proj_dbs/PDB_files_hpkd_models/pdbs/";

my (@fields, @unavailable_pdbs);

my %pdbid2path;

##############################
## Load list of PDB files in local mirror
foreach(File2Array("/aloy/data/dbs/pdbmirror/list_of_pdb_files")){
  #/aloy/data/dbs/pdbmirror/data/structures/divided/pdb/00/pdb400d.ent.gz
  @fields = split('\.', $_);
  if($fields[-1] eq "gz" && $fields[-2] eq "ent"){
    @fields = split("pdb",$fields[-3]);
    $pdbid2path{$fields[-1]}=$_; ## {pdbid}=pathtofile
  }
}
##############################

##############################
## Retrieving files in the list
print "copying....\n";
foreach $pdbid (File2Array("retrieve_pdb.list")){
  if(exists $pdbid2path{$pdbid}){
    copy("$pdbid2path{$pdbid}", $store_folder);
  }else{
    push(@unavailable_pdbs,$pdbid);
  }
}
##############################

##############################
## Unavailable pdb files 
if(0<@unavailable_pdbs){
  open(O,">unavailable_pdbs.list") or die;
  print "A list of unavailable pdbs is in: unavailable_pdbs.list\n";
  print O "$_\n" foreach(@unavailable_pdbs);
  close(O);
}
##############################





