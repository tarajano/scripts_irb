# created on: 24/01/2012 by M.Alonso
#
# USAGE:
#   PERL5LIB env variable:
#    update PERL5LIB variable in .bashrc
#    export PERL5LIB=${PERL5LIB}:/home/malonso/phd/kinome/scripts/modules/
#
# CALLING MODULE
#   use HPKsUtils;
#

use strict;
use warnings;
 
require Exporter;
package Interactome3DUtils;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(
                    retrieve_best_3D_model_for_binary_ppi_by_avg_seqs_cov_avg_seqs_ids
                    retrieve_best_3D_structure_for_binary_ppi_by_avg_seqs_cov_avg_seqs_ids
                    retrieve_best_3D_domdom_model_for_binary_ppi_by_avg_seqs_cov_avg_seqs_ids
                    );    # Symbols to be exported by default
#

##############################
###  The function queries and retrieves data of the 'best' 3D Domain-Domain
###  model for a PPI (if any) for a pair of Uniprot ACs.
###  The 'best' 3D Domain-Domain model will be selected by stable sorting of the
###  query results based on:
###   - 1) largest average coverage of sequences.
###   - 2) largest average sequence ids of sequences.
###  
### Usage:
###   my @model_data = retrieve_best_3D_domdom_model_for_binary_ppi_by_avg_seqs_cov_avg_seqs_ids(AC1, AC2)
###   
### Input:
###  - Two query Uniprot ACs
###   
### Returns:
###  - Ref. to array with data relative to the 3D structure found:
###     (prot1, chain1, seq_id1, cov1, prot2, chain2, seq_id2, cov2, pdbfile, resolution, avg_seqs_coverage)
###   
sub retrieve_best_3D_domdom_model_for_binary_ppi_by_avg_seqs_cov_avg_seqs_ids{
  my ($ac1, $ac2) = ($_[0], $_[1]);
  my @results=();
  my $conn = DBServer::connect2interactome3D();
  
  ### Querying Interactome3D with ACs in the original and intended order:
  ### (PK_AC - AS_AC or AS_AC - SUBS_AC)
  my $query = $conn->prepare("SELECT prot1, domain1, chain1, seq_id1, cov1, prot2, domain2, chain2, seq_id2, cov2, pdbid, resolution, filename, ((seq_id1 + seq_id2)/2) as avg_seqs_id, ((cov1 + cov2)/2) as avg_covs ".
                             "FROM interaction_dom_dom_models ".
                             "WHERE (prot1=? AND prot2=?) ".
                             "ORDER BY avg_covs DESC, avg_seqs_id DESC ". 
                             "LIMIT 1") or die $conn->errstr;
  $query->execute($ac1, $ac2) or die $conn->errstr;
  ### Fetchign query results
  @results = $query->fetchrow_array();
  $query->finish();
  ### Checking for results and roundinf decimal places of avg_covs, avg_seqs_ids
  if(0 < scalar @results){
    $results[-1] = sprintf("%.2f", $results[-1]);
    $results[-2] = sprintf("%.2f", $results[-2]);
    return @results;
  }
  
  ### Query reversing the order of ACs.
  ### Since I _care_ about the order of ACs in the final output file
  ### I must keep track of their relative positions (PK_AC - AS_AC or AS_AC - SUBS_AC)
  ### when querying Interactome3D. 
  ### Note that the oder of protein1,protein2 has been swichted to
  ### to protein2,protein1 in the SELECT argument and that also the order
  ### of ac1,ac2 has been swichted to ac2,ac1 in the ->execute statement.
  my $queryReverse = $conn->prepare("SELECT prot2, domain2, chain2, seq_id2, cov2, prot1, domain1, chain1, seq_id1, cov1, pdbid, resolution, filename, ((seq_id1 + seq_id2)/2) as avg_seqs_id, ((cov1 + cov2)/2) as avg_covs ".
                             "FROM interaction_dom_dom_models ".
                             "WHERE (prot1=? AND prot2=?) ".
                             "ORDER BY avg_covs DESC, avg_seqs_id DESC ". 
                             "LIMIT 1") or die $conn->errstr;
  $queryReverse->execute($ac2, $ac1) or die $conn->errstr;
  ### Fetchign query results
  @results = $queryReverse->fetchrow_array();
  $queryReverse->finish();
  ### Rounding decimal places of avg_covs, avg_seqs_ids
  if(0 < scalar @results){
    $results[-1] = sprintf("%.2f", $results[-1]);
    $results[-2] = sprintf("%.2f", $results[-2]);
  }
  return @results;
}
##############################

##############################
###  The function queries and retrieves data of the 'best' 3D PPI model
###  available (if any) for a pair of Uniprot ACs.
###  The 'best' PPI 3D model will be selected by stable sorting of the
###  query results based on:
###   - 1) largest average coverage of sequences.
###   - 2) largest average sequence ids of sequences.
###  
### Usage:
###   my @model_data = retrieve_best_3D_model_for_binary_ppi_by_avg_seqs_cov_avg_seqs_ids(AC1, AC2)
###   
### Input:
###  - Two query Uniprot ACs
###   
### Returns:
###  - Ref. to array with data relative to the 3D structure found:
###     (prot1, chain1, seq_id1, cov1, prot2, chain2, seq_id2, cov2, pdbfile, resolution, avg_seqs_coverage)
###   
sub retrieve_best_3D_model_for_binary_ppi_by_avg_seqs_cov_avg_seqs_ids{
  my ($ac1, $ac2) = ($_[0], $_[1]);
  my @results;
  my $conn = DBServer::connect2interactome3D();
  
  ### Querying Interactome3D with ACs in the original and intended order:
  ### (PK_AC - AS_AC or AS_AC - SUBS_AC)
  my $query = $conn->prepare("SELECT prot1, chain1, seq_id1, cov1, prot2, chain2, seq_id2, cov2, pdbfile, resolution, filename, ((seq_id1 + seq_id2)/2) as avg_seqs_id, ((cov1 + cov2)/2) as avg_covs ".
                             "FROM interaction_models ".
                             "WHERE (prot1=? AND prot2=?)".
                             "ORDER BY avg_covs DESC, avg_seqs_id DESC ". 
                             "LIMIT 1") or die $conn->errstr;
  $query->execute($ac1, $ac2) or die $conn->errstr;
  ### Fetchign query results
  @results = $query->fetchrow_array();
  $query->finish();
  ### Checking for results and roundinf decimal places of avg_covs, avg_seqs_ids
  if(0 < scalar @results){
    $results[-1] = sprintf("%.2f", $results[-1]);
    $results[-2] = sprintf("%.2f", $results[-2]);
    return @results;
  }
  
  ### Query reversing the order of ACs.
  ### Since I _care_ about the order of ACs in the final output file
  ### I must keep track of their relative positions (PK_AC - AS_AC or AS_AC - SUBS_AC)
  ### when querying Interactome3D. 
  ### Note that the oder of protein1,protein2 has been swichted to
  ### to protein2,protein1 in the SELECT argument and that also the order
  ### of ac1,ac2 has been swichted to ac2,ac1 in the ->execute statement.
  my $queryReverse = $conn->prepare("SELECT prot2, chain2, seq_id2, cov2, prot1, chain1, seq_id1, cov1, pdbfile, resolution, filename, ((seq_id1 + seq_id2)/2) as avg_seqs_id, ((cov1 + cov2)/2) as avg_covs ".
                             "FROM interaction_models ".
                             "WHERE (prot1=? AND prot2=?) ".
                             "ORDER BY avg_covs DESC, avg_seqs_id DESC ". 
                             "LIMIT 1") or die $conn->errstr;
  $queryReverse->execute($ac2, $ac1) or die $conn->errstr;
  ### Fetchign query results
  @results = $queryReverse->fetchrow_array();
  $queryReverse->finish();
  ### Rounding decimal places of avg_covs, avg_seqs_ids
  if(0 < scalar @results){
    $results[-1] = sprintf("%.2f", $results[-1]);
    $results[-2] = sprintf("%.2f", $results[-2]);
  }
  return @results;
}
##############################

##############################
###  The function queries and retrieves data of the 'best' 3D PPI structure
###  available (if any) for a pair of Uniprot ACs.
###  The 'best' PPI 3D structure will be selected by stable sorting of
###  the query results based on:
###   - 1) largest average coverage of sequences.
###   - 2) largest average sequence ids of sequences.
###  
### Usage:
###   my @str_data = retrieve_best_3D_structure_for_binary_ppi_by_avg_seqs_cov_avg_seqs_ids(AC1, AC2)
###   
### Input:
###  - Two query Uniprot ACs
###   
### Returns:
###  - Ref. to array with data relative to the 3D structure found:
###     (prot1, chain1, seq_id1, cov1, prot2, chain2, seq_id2, cov2, pdbfile, resolution, avg_seqs_coverage)
###   
sub retrieve_best_3D_structure_for_binary_ppi_by_avg_seqs_cov_avg_seqs_ids{
  my ($ac1, $ac2) = ($_[0], $_[1]);
  my @results;
  my $conn = DBServer::connect2interactome3D();
  
  ### Querying Interactome3D with ACs in the original and intended order:
  ### (PK_AC - AS_AC or AS_AC - SUBS_AC)
  my $query = $conn->prepare("SELECT prot1, chain1, seq_id1, cov1, prot2, chain2, seq_id2, cov2, pdbfile, resolution, ((seq_id1 + seq_id2)/2) as avg_seqs_id, ((cov1 + cov2)/2) as avg_covs ".
                             "FROM interaction_structures ".
                             "WHERE (prot1=? AND prot2=?) ".
                             "ORDER BY avg_covs DESC, avg_seqs_id DESC ". 
                             "LIMIT 1") or die $conn->errstr;
  $query->execute($ac1, $ac2) or die $conn->errstr;
  ### Fetchign query results
  @results = $query->fetchrow_array();
  $query->finish();
  ### Checking for results and roundinf decimal places of avg_covs, avg_seqs_ids
  if(0 < scalar @results){
    $results[-1] = sprintf("%.2f", $results[-1]);
    $results[-2] = sprintf("%.2f", $results[-2]);
    return @results;
  }
  
  ### Query reversing the order of ACs.
  ### Since I _care_ about the order of ACs in the final output file
  ### I must keep track of their relative positions (PK_AC - AS_AC or AS_AC - SUBS_AC)
  ### when querying Interactome3D. 
  ### Note that the oder of protein1,protein2 has been swichted to
  ### to protein2,protein1 in the SELECT argument and that also the order
  ### of ac1,ac2 has been swichted to ac2,ac1 in the ->execute statement.
  my $queryReverse = $conn->prepare("SELECT prot2, chain2, seq_id2, cov2, prot1, chain1, seq_id1, cov1, pdbfile, resolution, filename, ((seq_id1 + seq_id2)/2) as avg_seqs_id, ((cov1 + cov2)/2) as avg_covs ".
                             "FROM interaction_structures ".
                             "WHERE (prot1=? AND prot2=?) ".
                             "ORDER BY avg_covs DESC, avg_seqs_id DESC ". 
                             "LIMIT 1") or die $conn->errstr;
  $queryReverse->execute($ac2, $ac1) or die $conn->errstr;
  ### Fetchign query results
  @results = $queryReverse->fetchrow_array();
  $queryReverse->finish();
  ### Rounding decimal places of avg_covs, avg_seqs_ids
  if(0 < scalar @results){
    $results[-1] = sprintf("%.2f", $results[-1]);
    $results[-2] = sprintf("%.2f", $results[-2]);
  }
  return @results;
}
##############################



1;
