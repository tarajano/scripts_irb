#!/usr/bin/env perl
#
# created on: 27/Jan/2012 at 14:45 by M.Alonso
#
# Provide a list of elements and will create a 
# pairwise list of type PWListLength = (N * (N-1) )/2
#
#

use strict;
use warnings;
use LoadFile;


unless (defined $ARGV[0]){
  print "Usage:\n./pairwise_from_list.pl INPUTLIST\n\n\n";
  die "";
}

my $outputfile = $ARGV[0].".pairwise";
my @fields = File2Array($ARGV[0]);

##############################
my ($i,$ii)=0;
open(O, ">$outputfile") or die;
for($i=0; $i<$#fields; $i++){
  for($ii = $i+1; $ii<=$#fields; $ii++){
    print O "$fields[$i] $fields[$ii]\n";
  }
}
close(O);
##############################
