#!/usr/bin/env perl
#
# created on: 20/Jul/2012 at 09:47 by M.Alonso
#
# Maps an input list of Uniprot ACs to GeneIDs using 
# mappings available in Uniprot DB.
#
#

use strict;
use warnings;
#use Statistics::R;
#use List::MoreUtils qw(uniq);

use LoadFile;
#use ListCompare qw(retrieve_intersection retrieve_union);
use DBServer;

my @fields;
my @target_ACs;
my %ac2geneid_mappings; # {ac}=geneid


##############################
### Connecting to DB uniprotkb_2011_11
my $conn = connect2db("uniprotkb_2011_11", "uniprot_user", "uniprot");
##############################

##############################
### Loading list of uniprot ACs to map
@target_ACs = File2Array("/aloy/home/malonso/phd_proj_dbs/human_proteome/humanproteome.acs");
##############################


##############################
### Producing mapping and storing in output file

%ac2geneid_mappings = %{ mapping_AC2GID(@target_ACs) };

open(O, ">humanproteome.ac2geneid") or die;
print O "ac\tgeneid\n";
foreach(sort keys %ac2geneid_mappings){
  print O "$_\t$ac2geneid_mappings{$_}\n";
}
close(O);
##############################

##############################
####### SUBROUTINES ##########
##############################
sub mapping_AC2GID{
  
  my @target_ACs = @_;
  
  my $ac;
  my $count=1;
  my $target_ACs_size = @target_ACs;
  my %ac2geneid_mappings=();
  my @row;
  
  ### Preparing mapping query 
  my $query = $conn->prepare( "SELECT uniprot_ac, xref FROM uniprotkb_xref WHERE uniprot_ac=? AND db='geneid'" ) or die $conn->errstr;;
  
  ### querying 
  foreach $ac (@target_ACs){
    print "  mapping $count / $target_ACs_size\n";
    $count++;
    $query->execute($ac) or die $conn->errstr;
    @row = $query->fetchrow_array();
    ## Checking if a mapping was found
    if( 0 == scalar(@row) ){ $ac2geneid_mappings{$ac}="-"; }
    else{ $ac2geneid_mappings{$ac}=$row[1];}
  }
  
  $query->finish;
  return \%ac2geneid_mappings;
}
##############################
