#!/usr/bin/env perl
#
# Script used for populating the DB of HPKDomains (hpkd_models_db).
# For a description of this DB read "hpkd_models_db.readme".
# 
# Input files for thsi script:
#  - hpkd.fasta: sequences of 516 hpkds
#  - 531_hpkd_G_F_SF_P.tab: classification of 531 hpkds
#  - 875strs.list: list of strs/templates available for the 132 hpkds for which at least one str/tmpl was found
#  - 862pdbs.org_dist_summary: strs/templs PDBs and their corresponding source organisms
#  - hpkd_strs.SI95QC95: scanpdb results (at SI,QC>=95) for the 531 hpkds 
#
#  Sections of the script:
#   - Sections I,VI: connecting/disconnecting to DB 
#   - Section II: Loading hpkds sequences and classifications and storign them in the table hpkd_db.hpkd 
#     - NOTE: at this point the field "hpkd_hasmodel" is set to FALSE but this will be later updated when the data from strs/templates is inserted
#   - Section III: Loading data from PDB-SourceOrganisms and the list of 875 strs/templates for hpkds
#   - Section IV: Loading the results of the scanpdb and choosing non-redundant str/template solutions for each hpkd
#   - Section V: Loading strs/template data into table hpk_db.hpkd_templates & updating "hpkd_hasmodel" field in table hpk_db.hpkd
#
#
#

use strict;
use warnings;
use DBI;

my %hpkd_seqs=();
my %pdb_source_orgs=();
my @hpkd_classif=();
my @table_strs_templates=();
my $hpkd;


## Section - I 
###################
## connecting DB
my $conn = DBI->connect("dbi:Pg:dbname=hpkd_db;host=localhost;port=5433;user=malonso;password='manuel'");
###################


## Section - II
###################
###################
## Storing HPKD sequences file
open(I,"/home/malonso/phd/kinome/hpk/hpkd.fasta") or die;
while(<I>){
  chomp;
  if(/^>(.+)\s\(/){$hpkd=$1;}
  else{$hpkd_seqs{$hpkd}=$_;}
}
close(I);
## Storing HPKD classification file
## AGC_DMPK_GEK_DMPK1
open(I,"/home/malonso/phd/kinome/hpk/531_hpkd_G_F_SF_P.tab") or die;
@hpkd_classif=<I>;
chomp(@hpkd_classif);
close(I);
## Populating hpkd_db
foreach (@hpkd_classif){
  my ($group,$fam,$subfam,$protname) = split("_", $_); # AGC_DMPK_GEK_DMPK1
  
  $hpkd_seqs{$protname}="" unless (exists $hpkd_seqs{$protname});

  ## Prepare data insertion in table hpkd
  ## NOTE: (hpkd_hasmodel field still to be modified)
  my $query = $conn->prepare("INSERT INTO hpkd (hpkd_group,hpkd_family,hpkd_subfamily,hpkd_name,hpkd_sequence,hpkd_hasmodel) ".
                            "VALUES('$group','$fam','$subfam','$protname','$hpkd_seqs{$protname}','FALSE')") or die $conn->errstr;
  $query->execute() or die $conn->errstr;
}
###################
###################

## Section - III
###################
###################
## Storing PDB source organisms
open(I,"/home/malonso/phd/kinome/hpk/hpkdoms/hpkd_SI95QC95/862pdbs.org_dist_summary") or die;
while(<I>){
  #pdb_source_orgs
  chomp;
  unless (/^#/){
    my @fields=split(";");
    $fields[0] =~ /(^\w{4})\s+(.+)/;
    $pdb_source_orgs{lc($1)}=$2;
  }  
}
close(I);
## Storing 875 hpkds with strs/templates
## AGC_AKT__AKT1_3cquA
open(I,"/home/malonso/phd/kinome/hpk/hpkdoms/hpkd_SI95QC95/875strs.list") or die;
my @strs_templates=<I>;
chomp(@strs_templates);
close(I);
###################
###################

## Section - IV
###################
###################
## Collecting non redundant solutions for the 875 hpkds with strs/templates
## For more details on this procedure see script "retrieve_pdbstrs_from_scanpdb_v2.pl"
##
my (@infile,@fields,@prev_fields,@non_indentical_pdbs,%non_indentical_pdbs);
my $flag=0;

## read in scanpdb output file
open(I,"/home/malonso/phd/kinome/hpk/hpkdoms/hpkd_SI95QC95/hpkd_strs.SI95QC95") or die;
@infile=<I>;
chomp(@infile);
close(I);

## Eliminating the redundant solutions (same PDB, same chain) for every query. 
$flag=0;
my %tmphash=();
my $line;
foreach $line (@infile){
  @fields = split("\t",$line);
  
  ## Do nothing on first line
  if($flag>0){
    ## If Query and PDB are the same of the previous record
    ## store both solutions in a tmphash{e-value}
    if($fields[0] eq $prev_fields[0] && $fields[2] eq $prev_fields[2]){
      $tmphash{$fields[15]}=$line;
      $tmphash{$prev_fields[15]}=join("\t",@prev_fields);
    }else{
      ## sort the hash by the e-value (smaller values first)
      my @keys = sort { $a <=> $b } keys %tmphash;
      ## If not empty, process the %tmphash{e-value}
      if(scalar(@keys)!=0){
        push(@non_indentical_pdbs, $tmphash{$keys[0]});
        %tmphash=();
      }else{
        push(@non_indentical_pdbs, $line);
      }
    }
  }else{$flag++;}
  @prev_fields=@fields;
}
##### processing the last entries of the scanpdb file
## sort the hash by the e-value (smaller values first)
my @keys = sort { $a <=> $b } keys %tmphash;
## If not empty, process the %tmphash{e-value}
if(scalar(@keys)!=0){
  push(@non_indentical_pdbs, $tmphash{$keys[0]});
  %tmphash=();
}else{
  push(@non_indentical_pdbs, $line);
}
## @non_indentical_pdbs # TK_Syk__SYK  249 1xbb  A 268 240 249 240 1 249 9 248 96.4  100.0 89.6  1e-132
###################
###################

## Section - V
###################
###################
## Loading strs/template data into table hpk_db.hpkd_templates
## Updating "hpkd_hasmodel" field in table hpk_db.hpkd
##

my $tmp;
my @tmp;
my ($pdbidA,$pdbidB);
my ($chainA,$chainB);
my ($hpk_dom_nameA,$hpk_dom_nameB);
my ($si,$qc,$sc,$evalue,$model_file_name);

## Grabbing HPKD_name, PDBid & chain for each of the 875 hpks with strs/templates 
foreach my $str_tmp (@strs_templates){## AGC_AKT__AKT1_3cquA
  ## grabbing hpkd name
  @fields=split("_",$str_tmp);
  ($hpk_dom_nameA,$tmp)=($fields[3],$fields[4]); # (hpkd_name,pdbidchain)
  ## grabbing pdbid & chain 
  @fields=split("",$tmp);
  $pdbidA=join("",@fields[0..3]);
  $chainA=$fields[4];
  
  ## grabbing scanpdb values for each HPKD with strs/tmpl
  ## TK_Syk__SYK  249 1xbb  A 268 240 249 240 1 249 9 248 96.4  100.0 89.6  1e-132
  foreach (@non_indentical_pdbs){
    @fields=split("\t",$_);
    my @tmp=split("_",$fields[0]);
    ## grabbing hpkd_name, pdbid, chain
    $hpk_dom_nameB=$tmp[3];
    $pdbidB=$fields[2];
    $chainB=$fields[3];
   
    ## Locating the scanpdb data for each of the 875 hpkd models & 
    ## constructing the query to be inserted in the DB
    if($hpk_dom_nameA eq $hpk_dom_nameB && $pdbidA eq $pdbidB && $chainA eq $chainB){
      $si=$fields[12];
      $qc=$fields[13];
      $sc=$fields[14];
      $evalue=$fields[15];
      $model_file_name=$str_tmp.".pdb";
      my $pdbchain = join("",$pdbidA,$chainA);
      
      ## hpkdomain_name, PDBid_Chain, PDB_SourceOrg, SI, QC, SC, E-value, model/template_filename
      #print "$hpk_dom_nameA, $pdbchain, $pdb_source_orgs{$pdbidA},$si,$qc,$sc,$evalue,$model_file_name\n";
      
      ## Loading strs/template data into table hpk_db.hpkd_templates
      my $query = $conn->prepare("INSERT INTO hpkd_templates (hpkd_name,pdbid_chain,pdb_source_org,sid,query_cov,subject_cov,evalue,template_file) ".
                                  "VALUES('$hpk_dom_nameA','$pdbchain','$pdb_source_orgs{$pdbidA}','$si','$qc','$sc','$evalue','$model_file_name')") or die $conn->errstr;
      $query->execute() or die $conn->errstr;
      ## Updating "hpkd_hasmodel" field in table hpk_db.hpkd
      $query = $conn->prepare("UPDATE hpkd SET hpkd_hasmodel='TRUE' WHERE hpkd_name='$hpk_dom_nameA'") or die $conn->errstr;
      $query->execute() or die $conn->errstr;
      last;
    }
  }
}
###################
###################


## Section - VI
###################
## disconnecting DB
$conn->disconnect();
$conn = undef;
###################
