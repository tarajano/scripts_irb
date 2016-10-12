# created on: 24/01/2012 by M.Alonso
#
# USAGE:
#   PERL5LIB env variable:
#    update PERL5LIB variable in .bashrc
#    export PERL5LIB=${PERL5LIB}:/home/malonso/phd/kinome/scripts/modules/
#
# CALLING MODULE
#   use PhosphoDBUtils;
#

use strict;
use warnings;

require Exporter;
package PhosphoDBUtils;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(  
                      load_pk_subs_exptype_db
                      load_pk_psites_exptype_db
                      load_pk_psites_seqs_exptype_db
                      );    # Symbols to be exported by default
#

##############################
###  Retrieves (via DB query) the psites sequences per kinase from the second
###  version of integ_phosphDB. The one that accounts for the experiment
###  type (i.e. in vivo, in vitro)
###  In the function call you must specify the desired experiment type.
###  
### Usage:
###  %hash = %{ load_pk_psites_seqs_exptype_db( "invivo|invitro|all" ) }
### 
### Input:
###   Data is retrieved from the local DB integrated_phosphodbs_122012
### 
### Returns:
###  A ref. to hash {PKAC}=[psite_seq1, psite_seq2 ... psite_seqN]
### 
### 
sub load_pk_psites_seqs_exptype_db{
  use DBServer;
  use List::MoreUtils qw(uniq);
  
  my $exptype = $_[0] or die "   Please provide one of [invivo|invitro|all] to the function load_pk_psites_seqs_exptype_db()\n";
  my ($query, $subs, $pk);
  my (@row, @fields);
  my %pk_psites_seqs_hash; ### {PKAC}=[psite_seq1, psite_seq2 ... psite_seqN]
  
  print "Loading phosphorylation sites sequences to kinase associations\n";
  
  ### Connecting to DB 
  my $conn = DBServer::connect2localhostdb('integrated_phosphodbs_122012');
  
  ### Preparing and executing query
  if($exptype eq "invivo"){
    $query = $conn->prepare('SELECT pk_ac, psiteseq FROM psites WHERE exptype LIKE \'%invivo%\' ') or die $conn->errstr;
    $query->execute() or die $conn->errstr;
  }elsif($exptype eq "invitro"){
    $query = $conn->prepare('SELECT pk_ac, psiteseq FROM psites WHERE exptype LIKE \'%vitro%\' AND exptype NOT LIKE \'%vivo%\' ') or die $conn->errstr;
    $query->execute() or die $conn->errstr;
  }elsif($exptype eq "all"){
    $query = $conn->prepare('SELECT pk_ac, psiteseq FROM psites') or die $conn->errstr;
    $query->execute() or die $conn->errstr;
  }
  
  ### Fetchign query results
  while(@row = $query->fetchrow_array()){
    $pk = $row[0];
    $subs = $row[1];
    push( @{$pk_psites_seqs_hash{$pk}}, $subs);
  }
  
  $query->finish();
  $conn->disconnect();
  
  return \%pk_psites_seqs_hash;
}
##############################

##############################
###  Retrieves (via DB query) the subs ACs per kinase from the second
###  version of integ_phosphDB. The one that accounts for the experiment
###  type (i.e. in vivo, in vitro)
###  In the function call you must specify the desired experiment type.
###  
### Usage:
###  %hash = %{ load_pk_subs_exptype_db( "invivo|invitro|all" ) }
### 
### Input:
###   Data is retrieved from the local DB integrated_phosphodbs_122012
### 
### Returns:
###  A ref. to hash {PKAC}=[subsACs]
### 
### 
sub load_pk_subs_exptype_db{
  use DBServer;
  use List::MoreUtils qw(uniq);
  
  my $exptype = $_[0] or die "   Please provide one of [invivo|invitro|all] to the function load_pk_subs_exptype_db()\n";
  my ($query, $subs, $pk);
  my (@row, @fields);
  my %pk_subs_hash; ### {PKAC}=[pk@subs@pos, pk@subs@pos]
  
  print "Loading substrates to kinase associations\n";
  
  ### Connecting to DB 
  my $conn = DBServer::connect2localhostdb('integrated_phosphodbs_122012');
  
  ### Preparing and executing query
  if($exptype eq "invivo"){
    $query = $conn->prepare('SELECT pk_ac, subst_ac FROM psites WHERE exptype LIKE \'%invivo%\' ') or die $conn->errstr;
    $query->execute() or die $conn->errstr;
  }elsif($exptype eq "invitro"){
    $query = $conn->prepare('SELECT pk_ac, subst_ac FROM psites WHERE exptype LIKE \'%vitro%\' AND exptype NOT LIKE \'%vivo%\' ') or die $conn->errstr;
    $query->execute() or die $conn->errstr;
  }elsif($exptype eq "all"){
    $query = $conn->prepare('SELECT pk_ac, subst_ac FROM psites') or die $conn->errstr;
    $query->execute() or die $conn->errstr;
  }
  
  ### Fetchign query results
  while(@row = $query->fetchrow_array()){
    $pk = $row[0];
    $subs = $row[1];
    push( @{$pk_subs_hash{$pk}}, $subs);
  }
  
  $query->finish();
  $conn->disconnect();
  
  ### Making substrates unique for each kinase.
  foreach (keys %pk_subs_hash){
    @{$pk_subs_hash{$_}} = uniq @{$pk_subs_hash{$_}};
  }
  
  return \%pk_subs_hash;
}
##############################

##############################
###  Retrieves (via DB query) the psites ids per kinase from the second
###  version of integ_phosphDB. Tshe one that accounts for the experiment
###  type (i.e. in vivo, in vitro)
###  In the function call you must specify the desired experiment type.
###  
### Usage:
###  %hash = %{ load_pk_psites_exptype_db( "invivo|invitro|all" ) }
### 
### Input:
###   Data is retrieved from the local DB integrated_phosphodbs_122012
### 
### Returns:
###  A ref. to hash {PKAC}=[pk@subs@pos, pk@subs@pos]
### 
### 
sub load_pk_psites_exptype_db{
  use DBServer;
  use LoadFile;
  
  my $exptype = $_[0] or die "   Please provide one of [invivo|invitro|all] to the function load_pk_subs_exptype_db()\n";
  my ($query, $psite, $pk);
  my (@row, @fields);
  my %pk_psite_hash; ### {PKAC}=[pk@subs@pos, pk@subs@pos]
  
  ### Connecting to DB 
  my $conn = DBServer::connect2localhostdb('integrated_phosphodbs_122012');
  
  ### Preparing and executing query
  if($exptype eq "invivo"){
    $query = $conn->prepare('SELECT pk_ac, subst_ac, posit, resi FROM psites WHERE exptype LIKE \'%invivo%\' ') or die $conn->errstr;
    $query->execute() or die $conn->errstr;
  }elsif($exptype eq "invitro"){
    $query = $conn->prepare('SELECT pk_ac, subst_ac, posit, resi FROM psites WHERE exptype LIKE \'%vitro%\' AND exptype NOT LIKE \'%vivo%\' ') or die $conn->errstr;
    $query->execute() or die $conn->errstr;
  }
  elsif($exptype eq "all"){
    $query = $conn->prepare('SELECT pk_ac, subst_ac, posit, resi FROM psites') or die $conn->errstr;
    $query->execute() or die $conn->errstr;
  }
  
  ### Fetchign query results
  while(@row = $query->fetchrow_array()){
    $pk = $row[0];
    $psite = LoadFile::joinat(@row);
    push( @{$pk_psite_hash{$pk}}, $psite);
  }
  
  $query->finish();
  $conn->disconnect();
  
  return \%pk_psite_hash;
}
##############################


1;
