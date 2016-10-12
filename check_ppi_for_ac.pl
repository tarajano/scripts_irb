#!/usr/bin/env perl
#
# created on: 05/Oct/2012 at 15:35 by M.Alonso
# 
# Give a list of ACs and check for how many of them are there  
# interactions in a given sif files.
# 
# Usage:
# ./script target_acs_file interactions_file
# 
# 

use strict;
use warnings;
use Data::Dumper; # print Dumper myDataStruct
#use Statistics::R;
use List::MoreUtils qw(uniq);

use LoadFile;
#use ListCompare qw(retrieve_intersection retrieve_union);
#use DBServer;

my $target_acs_in=0;
my $target_acs_total=0;
my (@target_acs_list, @interactions_file, @fields);
my %ppi_per_target_ac; 

##############################
### Loading target list
@target_acs_list = uniq File2Array($ARGV[0]);
$target_acs_total = scalar @target_acs_list; 

### Loading sif file
@interactions_file = uniq File2Array($ARGV[1]);
##############################

##############################
print "Progressing ... \n";
foreach my $ppi_pair (@interactions_file){
  @fields = splittab($ppi_pair);
  foreach my $ac (@target_acs_list){
    if($fields[0] eq $ac || $fields[1] eq $ac){
      if(exists $ppi_per_target_ac{$ac}){$ppi_per_target_ac{$ac}++;}
      else{$ppi_per_target_ac{$ac}=1;}
    }
  }
  last if ($target_acs_in == scalar keys %ppi_per_target_ac);
}

$target_acs_in = scalar keys %ppi_per_target_ac;
printf("At least one interaction for: %d/%d (%.2f pct) target proteins\n", $target_acs_in, $target_acs_total, ($target_acs_in*100)/$target_acs_total );

print "Printing file with interactions per seed protein\n";
open(O, ">$ARGV[0].ppi_x_ac") or die;
foreach(sort { $ppi_per_target_ac{$b} <=> $ppi_per_target_ac{$a} } keys %ppi_per_target_ac){
  print O "$_\t$ppi_per_target_ac{$_}\n";
}
close(O);

##############################














