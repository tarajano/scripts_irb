#!/usr/bin/env perl
#
#
#
use strict;
use warnings;

my @files=<*.fasta>;

open(O,">merged.fas") or die;

foreach(@files){
  /(.*)\.fasta/;
	my $domseq=`tail -n1 $_`;
	print O ">$1\n$domseq";
}
close(O);
