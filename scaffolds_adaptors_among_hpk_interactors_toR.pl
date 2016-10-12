#!/usr/bin/env perl
#
# created on: 20/Jul/2012 at 18:31 by M.Alonso
#
# Converting to input file format for the R script
# goStats_enrichment_GO.r
#
# Input File Format:
# k1 s1
# k1 s2
# k2 s1
# k2 s3
# k2 s4
# 
# Output File Format:
# k1 s1 s2
# k2 s1 s3 s4
# 

use strict;
use warnings;
use LoadFile;

my $infile;
my @fields;
my %pk_AS; #{geneID}=[geneIDs]

##############################
#$infile = "/aloy/scratch/malonso/scaffolds/ptck_q_0905/scheme3/partner-subs_interactions/randbgs/dists_substrates_interactome/subs_5_interactome_script.tab.ac2geneid";
$infile = $ARGV[0];
foreach(File2Array($infile)){
  @fields = splittab($_);
  push(@{$pk_AS{$fields[0]}}, $fields[1]);
}
print "pkGeneID\tsubsGeneIDs\n";
foreach( keys %pk_AS){
  printf("%s %s\n", $_, join(" ", sort @{$pk_AS{$_}} ));
}
##############################
