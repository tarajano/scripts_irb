#!/usr/bin/env perl
#
# created on: 11/Feb/2011 by M.Alonso
#
# populating tables rapido & rapido_rbs from DB r3ds_pairwise_superpositions
#
#
#
#
#

use DBI;
use strict;
use warnings;

###################
## connecting DB
my $conn = DBI->connect("dbi:Pg:dbname=r3ds_pairwise_superpositions;host=localhost;port=5433;user=malonso;password='manuel'");
###################


###################
open(I,"/aloy/scratch/malonso/struct_alignments/rapido/rapido_data_547_pairwise.dat.psql") or die;
#open(I,"/aloy/scratch/malonso/struct_alignments/rapido/test.l") or die;
my @rapido=<I>;
chomp(@rapido);
close(I);

my @fields;

my $insert_1 = $conn->prepare("INSERT INTO rapido (group1, fam1, subfam1, name1, pdbid1, group2, fam2, subfam2, name2, pdbid2, rmsd, num_aligned, len1, len2, lo_lim, hi_lim, flex_rmsd, num_rigid_bodies, num_rigid_pairs, status) ".
                              "VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) RETURNING id ") or die $conn->errstr;
my $insert_2 =  $conn->prepare("INSERT INTO rapido_rbs (id,dim,rmsd) VALUES(?,?,?)") or die $conn->errstr;

foreach (@rapido){
  @fields = split("\t",$_);
  $insert_1->execute(@fields[0..19]) or die $conn->errstr;
  
  while(my @row = $insert_1->fetchrow_array()){
    my $id = $row[0];
    my ($i,$ii);
    for ($i=20;$i<=$#fields;$i+=2){
      $ii=$i+1;
      $insert_2->execute($id,$fields[$i],$fields[$ii]) or die $conn->errstr;
      $insert_2->finish();
    }
  }
  $insert_1->finish();
}
###################


###################
## disconnecting DB
$conn->disconnect();
$conn = undef;
###################
