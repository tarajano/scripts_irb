#!/usr/bin/env perl
#
#
# In the Ac 2 AC mapping performed on the PhBase ACs there were several old ACs 
# that were merged into the same new AC. This script is for identifying them.
#

use strict;
use warnings;

my %query_list=();
my @fields;

open(F,$ARGV[0])or die; # provide the file with the AC 2 AC mapping
while(<F>){
  chomp;
  @fields = split("\t",$_);
  push(@{$query_list{$fields[1]}},$fields[0]);
}
close(F);

print "newAC\toldAC\n";
foreach (keys %query_list){
  print "$_";
  print "\t$_" foreach(@{$query_list{$_}});
  print "\n";
}
