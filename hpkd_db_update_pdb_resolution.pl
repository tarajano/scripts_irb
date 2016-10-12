#!/usr/bin/env perl
#
# created on: 21/Jan/2011 by M.Alonso
#
# Inserting PDB resolutions to the hpkd_db table hpkd_templates_realseq
#
#
#

use DBI;
use strict;
use warnings;

my %pdb_res=(); # %pdb_res{pdbid}=resolution

######################
## loading PDBS and resolutuions
open(I,"/home/malonso/phd/kinome/hpk/862pdbs_resolutions.txt") or die;
while(<I>){
  chomp();
  my ($pdb,$res)=split("\t",$_);
  $pdb_res{$pdb}=$res;
}
close(I);
######################


######################
######
## connecting DB
my $conn = DBI->connect("dbi:Pg:dbname=hpkd_db;host=localhost;port=5433;user=malonso;password='manuel'")or die DBI->errstr;

foreach (keys %pdb_res){
  print "$_\t$pdb_res{$_}\n";
  ## inserting pdb_resolutions in table
  my $query = $conn->prepare("UPDATE hpkd_templates_realseq SET pdb_res = $pdb_res{$_} WHERE pdbid LIKE '$_%' ")or die $conn->errstr;
  $query->execute() or die $conn->errstr;
  #$query->execute($pdb_res{$_},'$_%') or die $conn->errstr;
  $query->finish();
}
## disconnecting DB
$conn->disconnect();
######
######################
