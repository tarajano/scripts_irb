#!/usr/bin/env perl
#
# created on: 01/Dec/2011 at 09:53 by M.Alonso
#
# Merging PfamScan outputs, including at the end of the output file
# those sequences for which no Pfam domain was found.
#
# PfamScan outputs produced with:
# /aloy/data/programs/PfamScan_24.0/assign_pfam_domains.py /aloy/data/programs/PfamScan_24.0/pfam_scan.pl /aloy/data/dbs/pfam/Pfam24.0/ protein.fasta protein.pfamscan.out
#
#
#

use strict;
use warnings;
use LoadFile;

my $proteinID;
my @fields;
my @pfamscan_outfiles = <*.pfamscan.out>;
my @empty_pfamscan_outfiles;
my @merged_output;

##############################
foreach my $file (@pfamscan_outfiles){
  if(-z $file){
    @fields = split("/", $file);
    @fields = splitdot($fields[-1]);
    $proteinID = $fields[0];
    push(@empty_pfamscan_outfiles,$proteinID);
  }else{
    push(@merged_output, File2Array($file));
  }
}
## Adding at the end Ids of proteins for which no Pfam domain was found.
push(@merged_output, @empty_pfamscan_outfiles);
##############################

##############################
## Printing out
@merged_output = sort @merged_output;
open(O, ">merged_pfamscan_out.tab") or die;
print O "$_\n" foreach(@merged_output);
close(O)
##############################
