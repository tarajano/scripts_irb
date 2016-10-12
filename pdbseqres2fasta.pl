#!/usr/bin/env perl
#
# splitting protein chains in pdb_seqres to fasta files
#
use warnings;
use strict;

open(PDBSEQRES,$ARGV[0]) or die; # provide pdb_seqres.txt file
my @PDBSEQRESarray = <PDBSEQRES>;
chomp @PDBSEQRESarray;
close(PDBSEQRES);

my $lastsubscript = $#PDBSEQRESarray;

for(my $i=0;$i<=$lastsubscript;$i+=2){
  if ($PDBSEQRESarray[$i] =~ /^>(\w+)\s+mol:protein length:(\d+)/){
    if($2>=50){ # condition to look for chains >= than 50 residues
      print "$1\n";
      my $filename="fastas/".$1.".fasta";
      my $ii=$i+1;
      open(F,">$filename");
      print F "$PDBSEQRESarray[$i]\n";
      print F "$PDBSEQRESarray[$ii++]\n";
      close(F);
    }
  }
}

