#!/usr/bin/env perl
#
#
# There are 876 strs/templates and 862 diff PDB_chains, then 14 PDBchains are
# shared by some HPKDs (see __DATA__ section) .
#
# sql command used:
# SELECT pdbid_chain, mycount FROM
#  (SELECT pdbid_chain, count(*) as mycount FROM hpkd_templates 
#  GROUP BY pdbid_chain ORDER BY mycount DESC) as foo
# WHERE mycount > 1;
#
#

use DBI;
use strict;
use warnings;


###################
## connecting DB
my $conn = DBI->connect("dbi:Pg:dbname=hpkd_db;host=localhost;port=5433;user=malonso;password='manuel'");
###################

my $query;


while(<DATA>){
  chomp;
  my $pdbidchain = $_;
  $query = $conn->prepare("SELECT hpkd_name,pdbid_chain,pdb_source_org,sid,query_cov,subject_cov,evalue FROM hpkd_templates WHERE pdbid_chain = '$pdbidchain' ") or die $conn->errstr;
  $query->execute() or die $conn->errstr;

  my @row;
  while (@row = $query->fetchrow_array()){
    printf ("%s\n",join("\t",@row));
  }
  undef($query);
  ########
}


###################
## disconnecting DB
$conn->disconnect();
$conn = undef;
###################

__DATA__
1ckjB
1yhvA
3mvjB
1ctpE
3fxzA
2f7xE
2f7zE
2hy81
2f7eE
2ojfE
3fy0A
1yhwA
1ckiA
2oh0E
