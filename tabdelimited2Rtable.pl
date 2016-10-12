#!/usr/bin/env perl
#
# created on: 26/Apr/2012 at 17:34 by M.Alonso
#
use strict;
use warnings;
use LoadFile;
my $line;
my @fields;

foreach (File2Array($ARGV[0])){
  $line = s/_/\\_/g;
  @fields = splittab($_);
  $line  = join(" \& ", @fields);
  $line = $line."\\\\";
  print "$line\n";
}
