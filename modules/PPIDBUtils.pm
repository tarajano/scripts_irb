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
use List::MoreUtils qw(uniq);

require Exporter;
package PPIDBUtils;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(
                      querying_ppi_existence
                      querying_ppi_existence_fromHoH
                      
                      load_hs_protein_bin_partners
                      
                      fetch_all_proteins_in_hs_bin_ppi
                      
                      fetch_all_ppis_in_hs_bin_ppi
                      fetch_all_ppis_in_hs_bin_ppi2HoH
                      
                      
                    );    # Symbols to be exported by default
#

##############################
###  Test existence of a PPI between two human proteins.
###  
### Usage:
###  $ppi = querying_ppi_existence_fromHoH(\%hs_pin_hoh, \@ac_pair)
### 
### Input:
###   - Ref. to hash of hash containing the Hs PPIDB. 
###     - This data structure can be obtained from the subroutine PPIDBUtils::fetch_all_ppis_in_hs_bin_ppi2HoH()
###   - Ref. to array containing the human Uniprot ACs to be queried for PPI.
### 
### Returns:
###   - 1: if PPI exists. 0: if PPI does not exist.
###   
sub querying_ppi_existence_fromHoH{
  my %hoh = %{$_[0]};
  my ($ac1, $ac2) = sort {$a cmp $b} @{$_[1]}; ### ACs must be lexicographically sorted before querying the HoH.
  if(exists $hoh{$ac1}{$ac2}){ return 1; }
  else{ return 0; }
}
##############################

##############################
###  Fetches all protein-protein interactions in hs_bin_ppi
###  and stores them in a hash of hashes.
###  Keys (Uniprot ACs) are lexicograpically sorted before they are stored.
###  
### Usage:
###  %HoH = %{  fetch_all_ppis_in_hs_bin_ppi()  }
### 
### Input:
###   - nothing
### 
### Returns:
###   - Ref. to a hash of hashes {ac}{ac}=1
###   
sub fetch_all_ppis_in_hs_bin_ppi2HoH{
  use DBServer;
  
  my ($conn, $query);
  my (@row, @ppis);
  my %ppis; ### {acA}{acB}=1
  
  $conn = DBServer::connect2localhostdb('hs_bin_ppi');
  
  ### Preparing and executing queries
  $query = $conn->prepare(' SELECT uniref_canonical1, uniref_canonical2 FROM bin_ppi ') or die $conn->errstr;
  $query->execute() or die $conn->errstr;
  
  while ( @row = $query->fetchrow_array() ) {
    ### Sorting alphabetically before storing. This would ease the later
    ### identification of existing key pairs in the hash. Since you know
    ### that keys have been alphb. sorted, you wont have to try exist clause
    ### on both directions (i.e. exists $hash{k1}{k2} OR exists $hash{k2}{k1}),
    ### it will be enough to just sort the keys alphb. before testing their existence,
    ### (i.e.: (k1,k2) = sort {$a cmp $b} (k1,k2); exist $hash{k1}{k2}; ).
    @row = sort {$a cmp $b} @row;
    $ppis{$row[0]}{$row[1]}=1
  }
  
  $query->finish();
  $conn->disconnect();
  
  ### Returns a ref. to an hash of hash containing all PPIs in hs_bin_ppi
  return \%ppis;
}
##############################



##############################
###  Fetches all protein-protein interactions in hs_bin_ppi
###  
### Usage:
###  @ppis = @{  fetch_all_ppis_in_hs_bin_ppi()  }
### 
### Input:
###   - nothing
### 
### Returns:
###   - Ref. to an array of array containing all PPIs in hs_bin_ppi
### 
sub fetch_all_ppis_in_hs_bin_ppi{
  use DBServer;
  
  my ($conn, $query);
  my (@row, @ppis);
  
  $conn = DBServer::connect2localhostdb('hs_bin_ppi');
  
  ### Preparing and executing queries
  $query = $conn->prepare(' SELECT uniref_canonical1, uniref_canonical2 FROM bin_ppi ') or die $conn->errstr;
  $query->execute() or die $conn->errstr;
  
  while ( @row = $query->fetchrow_array() ) {
    ### Sorting alphabetically before storing. This would ease the later
    ### identification of existing key pairs in the hash. Since you know
    ### that keys have been alphb. sorted, you wont have to try exist clause
    ### on both directions (i.e. exists $hash{k1}{k2} OR exists $hash{k2}{k1}),
    ### it will be enough to just sort the keys alphb. before testing their existence,
    ### (i.e.: (k1,k2) = sort {$a cmp $b} (k1,k2); exist $hash{k1}{k2}; ).
    @row = sort {$a cmp $b} @row;
    push(@ppis,  [@row]);
  }
  
  $query->finish();
  $conn->disconnect();
  
  ### Returns a ref. to an array of arrray containing all PPIs in hs_bin_ppi
  return \@ppis;
}
##############################

##############################
###  Fetches all proteins in hs_bin_ppi
###  
### Usage:
###  @acs = @{  fetch_proteins_in_hs_bin_ppi()  }
### 
### Input:
###   - nothing
### 
### Returns:
###   - Ref. to an array containing all proteins in hs_bin_ppi
### 
sub fetch_all_proteins_in_hs_bin_ppi{
  use DBServer;
  use List::MoreUtils qw(uniq);
  
  my ($conn, $query);
  my (@row, @proteins);
  
  $conn = DBServer::connect2localhostdb('hs_bin_ppi');
  
  ### Preparing and executing queries
  $query = $conn->prepare(' SELECT DISTINCT ac FROM (SELECT uniref_canonical1 AS ac FROM bin_ppi UNION SELECT uniref_canonical2 AS ac FROM bin_ppi) AS tmp ') or die $conn->errstr;
  $query->execute() or die $conn->errstr;
  
  while ( @row = $query->fetchrow_array() ) {
    push(@proteins, $row[0]);
  }
  @proteins = uniq @proteins;
  
  $query->finish();
  $conn->disconnect();
  
  ### Returns a ref. to an array containing all proteins in hs_bin_ppi 
  return \@proteins;
}
##############################

##############################
###  Test if a binary interaction exists between two query proteins.
###  
### Usage:
###  $int = querying_ppi_existence( \@queryACpair )
### 
### Input:
###  - A ref. to an array containing the query ACs (canonical)
###  - Human PPI binary interaction data is retrieved from the local DB hs_bin_ppi
### 
### Returns:
###  - 0: if interaction does not exist
###  - 1: if interaction exists
### 
sub querying_ppi_existence{
  use DBServer;
  
  my $ppi_existence = 0; ### 0: if PPI does not exist. 1: if PPI exists
  
  my ($conn, $queryA, $queryB, $ac1, $ac2);
  my (@row);
  
  ($ac1, $ac2) = @{$_[0]};
  
  $conn = DBServer::connect2localhostdb('hs_bin_ppi');
  
  ### Preparing and executing queries
  $queryA = $conn->prepare('SELECT uniref_canonical1, uniref_canonical2 FROM bin_ppi WHERE (uniref_canonical1=? AND uniref_canonical2=?) ') or die $conn->errstr;
  $queryB = $conn->prepare('SELECT uniref_canonical1, uniref_canonical2 FROM bin_ppi WHERE (uniref_canonical1=? AND uniref_canonical2=?) ') or die $conn->errstr;
  $queryA->execute($ac1, $ac2) or die $conn->errstr;
  $queryB->execute($ac2, $ac1) or die $conn->errstr;
  
  ### Test if the PPI interaction was found by query A.
  ### Return 1 if found
  while ( @row = $queryA->fetchrow_array() ) {
    if( 0 < scalar(@row) ){
      $ppi_existence++;
      return $ppi_existence;
    }
  }
  
  ### Test if the PPI interaction was found by query B
  ### Return 1 if found
  while ( @row = $queryB->fetchrow_array() ) {
    if( 0 < scalar(@row) ){
      $ppi_existence++;
      return $ppi_existence;
    }
  }
  
  
  $queryA->finish();
  $queryB->finish();
  $conn->disconnect();
  
  ### Return 0 the interaction was not found
  return $ppi_existence;
  
}
##############################

##############################
###  Retrieves (via DB query) the binary ppi partners for the query ACs.
###  
### Usage:
###  %hash = %{ load_hs_protein_bin_partners( \@queryACs) }
### 
### Input:
###  - A ref. to an array containing the query ACs (canonical)
###  - Human PPI binary interaction data is retrieved from the local DB hs_bin_ppi
### 
### Returns:
###  - A ref. to hash {queryAC}=[PPIpartners]
### 
### 
sub load_hs_protein_bin_partners{
  use DBServer;
  use List::MoreUtils qw(uniq);
  
  my @queryACs = @{$_[0]};
  
  my($conn, $query, $queryac, $ac1, $ac2);
  my (@row);
  my %ac_ppipartners;
  
  $conn = DBServer::connect2localhostdb('hs_bin_ppi');
  $query = $conn->prepare('SELECT uniref_canonical1, uniref_canonical2 FROM bin_ppi WHERE uniref_canonical1=? OR uniref_canonical2=? ') or die $conn->errstr;
  
  foreach $queryac (@queryACs){
    #print "Querying hs_bin_ppi DB for $queryac\n";
    $query->execute($queryac, $queryac) or die $conn->errstr;

    ### Fetchign query results
    while(@row = $query->fetchrow_array()){
      
      ### Checking if no PPI was found for current queryAC
      if(0 == scalar(@row)){
        ### Assign empty array if no PPI was found
        @{$ac_ppipartners{$queryac}}=();
      }else{
        ($ac1, $ac2) = @row;
        ### Checking for self-interactions
        if($ac1 eq $ac2){
          push(@{$ac_ppipartners{$queryac}}, $queryac);
        ### Assigning PPI partners
        }else{
          if($ac1 eq $queryac){ push(@{$ac_ppipartners{$queryac}}, $ac2); }
          elsif($ac2 eq $queryac){ push(@{$ac_ppipartners{$queryac}}, $ac1); }
        }
      }
    }
    
  }
  $query->finish();
  $conn->disconnect();
  
  return \%ac_ppipartners;
}
##############################


1;
