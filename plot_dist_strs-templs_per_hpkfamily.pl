#!/usr/bin/env perl
#
# malonso Nov 2010
#
# Generating the data for the histogram of the distribution of Protein, Templates and Real Structures among the 
# 130 HPK families across the 10 PK groups.
#
# This script generates the data file that must be provided to GNUPLOT together with the script  "dist_strs-templs_per_hpkfamily.gnupot"
#
#


use strict;
use warnings;
use DBI;

my $index=0;
my ($query,$group,$family);
my ($pkgroup,$pkfam,$pkname,$templates,$realstructures);

my @row;
my @PKgroups=("AGC","CAMK","CK1","CMGC","Other","RGC","STE","TK","TKL","Atypical");

my %family_data=(); # {family}=[group,total_prots, templates, real_strs]
my %prots_in_family=(); # {family}=[p1, p2, p3, ...]
my %tmp_hash=();


###################
## connecting DB
my $conn = DBI->connect("dbi:Pg:dbname=hpkd_db;host=localhost;port=5433;user=malonso;password='manuel'");
###################

###################
## collecting proteins in each family {family}=[p1, p2, p3]
$query = $conn->prepare("SELECT hpkd_family,hpkd_name  FROM hpkd")or die $conn->errstr;
$query->execute() or die $conn->errstr;
while (@row = $query->fetchrow_array()){
  push(@{$prots_in_family{$row[0]}},$row[1]);
}
#print "$_: @{$prots_in_family{$_}}\n" foreach (sort {$b cmp $a} keys %prots_in_family);
###################

###################
## Collecting per-group families' classifications &&
## the total number of proteins per family
$query = $conn->prepare("SELECT hpkd_group, hpkd_family, count(hpkd_name) ".
                        "FROM hpkd ".
                        "GROUP BY hpkd_group,hpkd_family ".
                        "ORDER BY hpkd_group,hpkd_family")or die $conn->errstr;
$query->execute() or die $conn->errstr;

while (@row = $query->fetchrow_array()){
  $family_data{$row[1]}=[$row[0],$row[2]]; # {family}=[group,total_prots]
}
#print "$family_data{$_}[0]\t$_\t$family_data{$_}[1]\n" foreach (sort {$a cmp $b} keys %family_data);
###################

###################
## Counting the templates AND real structures per protein in each family
foreach $pkfam (keys %prots_in_family){
  $templates=0; $realstructures=0;
  
  foreach $pkname (@{$prots_in_family{$pkfam}}){
    ## counting templates per family
    $query = $conn->prepare("SELECT count(need_to_model) FROM hpkd_templates_realseq ".
                            "WHERE need_to_model='yes' AND hpkd_name='$pkname'")or die $conn->errstr;
    $query->execute() or die $conn->errstr;
    while (@row = $query->fetchrow_array()){
      $templates=($templates+$row[0]);
    }
    ## counting real structures per family
    $query = $conn->prepare("SELECT count(need_to_model) FROM hpkd_templates_realseq ".
                            "WHERE need_to_model='no' AND hpkd_name='$pkname'")or die $conn->errstr;
    $query->execute() or die $conn->errstr;
    while (@row = $query->fetchrow_array()){
      $realstructures=($realstructures+$row[0]);
    }
  }
  ## filling %family_data
  push(@{$family_data{$pkfam}},$templates);
  push(@{$family_data{$pkfam}},$realstructures);
}
###################

###################
## {family}=[group,total_prots, templates, real_strs]
foreach $pkgroup (@PKgroups){
  foreach $pkfam (sort {$a cmp $b} keys %family_data){
    if($pkgroup eq $family_data{$pkfam}[0]){
      #printf("%s\n",join("\t",@{$family_data{$pkfam}}));
      $index++;
      print "$pkgroup\t$pkfam\t$index\t$family_data{$pkfam}[1]\t$family_data{$pkfam}[2]\t$family_data{$pkfam}[3]\n";
    }
  }
  $index++;
  print "\n\n";
}
###################

###################
## disconnecting DB
$conn->disconnect();
###################
