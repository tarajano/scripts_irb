#!/usr/bin/env perl
#
#
# 
use strict;
use warnings;
use DBI;

## Section - I 
###################
## connecting DB
my $conn = DBI->connect("dbi:Pg:dbname=hpkd_db;host=localhost;port=5433;user=malonso;password='manuel'");
my $query;
my $update;
my @row;

$query = $conn->prepare("SELECT seqres.hpkd_name,seqres.pdbid FROM (SELECT hpkd_name,pdbid FROM hpkd_templates WHERE sid<100) as realseq, hpkd_templates_seqres as seqres ".
                        "WHERE seqres.hpkd_name=realseq.hpkd_name AND ".
                        "realseq.pdbid=seqres.pdbid AND ".
                        "seqres.sid=100 AND seqres.qc=100") or die $conn->errstr;                   
$query->execute() or die $conn->errstr;

################### THE DB HAS BEEN ALREADY UPDATED ! WATCH OUT BEFORE UNCOMMENTING THESE LINES
#while(@row = $query->fetchrow_array()){
  #my ($hpkd,$pdbid) = ($row[0],$row[1]);
  #$update = $conn->prepare("UPDATE hpkd_templates SET need_to_model='no' WHERE hpkd_name='$hpkd' AND pdbid='$pdbid'") or die $conn->errstr;
  #$update->execute() or die $conn->errstr;
#}
#$update = $conn->prepare("UPDATE hpkd_templates SET need_to_model='no' WHERE sid=100 AND qc=100") or die $conn->errstr;
#$update->execute() or die $conn->errstr;
#$update = $conn->prepare("UPDATE hpkd_templates SET need_to_model='yes' WHERE need_to_model='-'") or die $conn->errstr;
#$update->execute() or die $conn->errstr;
###################


###################
## disconnecting DB
$conn->disconnect();
$conn = undef;
###################
