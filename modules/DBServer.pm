# created on: 03/Jan/2012 by M.Alonso
#
# USAGE:
#   PERL5LIB env variable:
#    update PERL5LIB variable in .bashrc
#    export PERL5LIB=${PERL5LIB}:/home/malonso/phd/kinome/scripts/modules/
#
# CALLING MODULE
#   use DBServer;
#
#
#
#

use strict;
use warnings;
use DBI; 

require Exporter;
package DBServer;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(
                    connect2db
                    disconnectdb
                    connect2localhostdb
                    connect2interactome3D
                    disconnect2interactome3D
                    );    # Symbols to be exported by default
#



#############
### Connecting to DBs in Aloy DB server
### 
### Usage:
### my $conn = connect2db(database, user, passw);
### 
sub connect2db {
  my ($conn,$source);
  my $db = $_[0];
  my $user = $_[1];
  my $passw = $_[2];
  $source="dbi:Pg:database=$db; host=pac-node105; port=5432";
  $conn = DBI->connect($source,$user,$passw) or die $conn->errstr;
  return $conn;
}
#############

#############
### Connecting to Interactome3D DB in Web Server
### 
### Usage:
### my $conn = connect2interactome3D();
### 
sub connect2interactome3D{
  my $source='dbi:Pg:database=interactome3d_2011_11; host=aloy-websrv; port=5432';
  my $conn = DBI->connect($source,'interactome3d_viewer','int3d_view') or die;
}
#############

#############
### Disconnecting from Interactome3D DB in Web Server
### 
### Usage:
### disconnect2interactome3D(conn_int3D);
### 
sub disconnect2interactome3D{
  my $discon = $_[0];
  $discon->disconnect() or die $discon->errstr;
}
#############


#############
### Connecting to DBs in localhost
### 
### Usage:
### my $conn = connect2localhostdb(database);
### 
sub connect2localhostdb {
  
  my ($conn,$source);
  my $db = $_[0];
  
  $source="dbi:Pg:database=$db; host=localhost; port=5432";
  $conn = DBI->connect($source,"malonso","IRB800523") or die;
  
  return $conn;
}
#############


#############
sub disconnectdb{
  my $discon = $_[0];
  $discon->disconnect() or die $discon->errstr;
}
#############



1;
