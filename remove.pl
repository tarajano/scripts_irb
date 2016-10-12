#!/usr/bin/env perl
#
#

use strict;
use warnings;


my %acs;
open(F,$ARGV[0]) or die; # acs' list
while(<F>){
  chomp;
  $acs{$_}=1;
}
close(F);

my @files=</aloy/scratch/malonso/pphosphatase/139HPP_folder/pfamscanout_EC_PhBase_merged/fastas/*.out>;

foreach(@files){
  /(\w{6,8})\.fasta\.pfamscan\.out$/;
  unlink $_ unless(exists $acs{$1});
}

