#!/usr/bin/env perl
#
#
# to building a 1st || 2nd || 3th level network starting from seed proteins
# VERSION: version used until March 25th 2010
# Modified on: Dec 16 2011
#
#
#
# usage:
# ./find_2nd_level UniProtAC || UniProtAClisfile
#
#
#
# this one was used for extended interactions in ALL ORGANISMS
#
use DBI;
use strict;
use warnings;

use DBServer;

# Die if no arguments are provided
die "need arguments!!\n" unless ($ARGV[0]); 

my $DBsource="dbi:Pg:database=ppidb_2011_11; host=pac-node3; port=5432";
my $DBuser="ppi_select";
my $DBpassw="ppi";

my $conn = DBI->connect($DBsource,$DBuser,$DBpassw) or die;
my $uniprotac;

##############################
if(-e $ARGV[0]){
  # If the argument to the script IS a file with UniprotACs:
  # read file line by line and query the DB for each AC
  open(F,$ARGV[0]) or die;
  my @infile=<F>; chomp(@infile);
  close(F);
  foreach $uniprotac (@infile){Neighbours($uniprotac);}
}else{
  # if the argument to the script IS a single UniProtAC:
  #  search in DB for this AC
  $uniprotac = $ARGV[0];
  chomp($uniprotac);
  Neighbours($uniprotac);
}
##############################

$conn->disconnect();
$conn = undef;

##############################
####### SUBROUTINES ##########
##############################

##############################
sub Neighbours{
  
  my %interactors=();
  my %sec_nodes=(); my %third_nodes=();  # seed nodes for the 2nd & 3th -levels neighbourhoods
  my $key; my @row=""; my $queryAC = $_[0];
  
  open(OUTFILE,">$queryAC.neighb") or die;
  
  ######### FIRSTS NEIGHBOURS
  my $query = $conn->prepare(
  # retrieving interactions from any organism in PPI DB
  "SELECT uniref_canonical1, uniref_canonical2 ".
  "FROM ppidb_interactions ".
  "WHERE (uniref_canonical1='$queryAC' OR uniref_canonical2='$queryAC') AND ".
  "uniprot_taxid1='9606' AND uniprot_taxid2='9606' AND ".
  "active_uniprot_proteins=TRUE AND ".
  "ambiguous_mapping=FALSE AND ".
  #"(method_binary=TRUE OR curation_binary=TRUE)"
  "size = 2"
  );
  $query->execute();
  #########
  while (@row = $query->fetchrow_array()){
    $key=join("\t",@row);
    $interactors{$key}=1;
    
    ## Seed nodes for 2nd-level neighbourhood
    if($row[0] ne $queryAC){$sec_nodes{$row[0]}=1;}
    elsif($row[1] ne $queryAC){$sec_nodes{$row[1]}=1;}
  }
  
  printf OUTFILE ("$_\n") foreach (keys %interactors);
  #########

  ######### SECOND NEIGHBOURS
  @row="";
  %interactors=();
  foreach $queryAC (keys %sec_nodes){
    $query = $conn->prepare(
    "SELECT uniref_canonical1, uniref_canonical2 ".
    "FROM ppidb_interactions ".
    "WHERE (uniref_canonical1='$queryAC' OR uniref_canonical2='$queryAC') AND ".
    "uniprot_taxid1='9606' AND uniprot_taxid2='9606' AND ".
    "active_uniprot_proteins=TRUE AND ".
    "ambiguous_mapping=FALSE AND ".
    #"(method_binary=TRUE OR curation_binary=TRUE)"
    "size = 2"
    );
    $query->execute();
    while (@row = $query->fetchrow_array()){
      $key=join("\t",@row);
      $interactors{$key}=1;
      ## Seed nodes for 3th-level neighbourhood
      if($row[0] ne $queryAC){$third_nodes{$row[0]}=1;}
      elsif($row[1] ne $queryAC){$third_nodes{$row[1]}=1;}
    }
    printf OUTFILE ("$_\n") foreach (keys %interactors);
  } 
  #########

  ########### THIRD NEIGHBOURS
  ##@row="";
  ##%interactors=();
  ##foreach(keys %third_nodes){
    ##$query = $conn->prepare(
    ##"SELECT uniref_canonical1, uniref_canonical2 ".
    ##"FROM ppidb_interactions ".
    ##"WHERE (uniref_canonical1='$_' OR uniref_canonical2='$_') AND ".
    ##"uniprot_taxid1='9606' AND uniprot_taxid2='9606' AND ".
    ##"active_uniprot_proteins=TRUE AND ".
    ##"ambiguous_mapping=FALSE AND ".
    ##"(method_binary=TRUE OR curation_binary=TRUE) AND ".
    ##"weak=FALSE"
    ##);
    ##$query->execute();
    ##while (@row = $query->fetchrow_array()){
      ##$key=join("\t",@row);
      ##$interactors{$key}=1;
    ##}
    ##printf OUTFILE ("$_\n") foreach (sort keys %interactors);
    ##undef($query);
  ##}
  #########

  close(OUTFILE);
}
##############################

