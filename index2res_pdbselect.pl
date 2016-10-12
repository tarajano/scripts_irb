#!/usr/bin/env perl
#
# using the bestmodels file for locating the best structures in the PDB
#
# NOTES:
# 1 - re-run the scanPDB on the PDB database given by Roberto (PDB_fasta/pdb_seqres_prot_xray_NMR_real_seqs)
# 2 - get the numbers of ini and end residues from best resutls file
      #- make ini and end residues zero-based (minus 1 to ini and end values)
# 3 - retrive the real rsidue number for each ini and end residues in thwe PDB file by using 
# /aloy/data/programs/rosa/bin/index2res /aloy/data/dbs/pdbmirror/structures/pdb1yz4.ent A 14
# /aloy/data/programs/rosa/bin/index2res /aloy/data/dbs/pdbmirror/structures/pdb1yz4.ent A 142
# 4 - then retrieve the corresponding PDB fragament by using
# /aloy/data/programs/rosa/bin/pdbselect -o test.pdb "chain A and resi 12:140" /aloy/data/dbs/pdbmirror/structures/pdb1yz4.ent
#
#
use strict;
use warnings;

my $pdbmirror= "/aloy/data/dbs/pdbmirror/structures/";
my (@bestmods);

### input bestmodels file 
# @fields:
# A4D256_PF00782_316-443  1ohc_A  1 128 201 328 97.7  100.0 36.8  4e-72 2.5 X-RAY
#
open(F,$ARGV[0]) or die; # provide bestmodels file
@bestmods=<F>;
chomp(@bestmods);
close(F);
###

## Extracting PDBids from bestmodels file and
## fetching the corresponding structures fragments from PDB DB.
foreach (@bestmods){
  print "processing $_\n";
  my @fields = split("\t",$_);
  if(defined $fields[1]){
    my ($pdbid,$chain) = split("_",$fields[1]); # spliting the string PDBid_chain
    my ($index_ini,$index_end) = ($fields[4],$fields[5]); # getting resnumbs in PDB 
    $index_ini--; # Making the residues indexes zero-based so that
    $index_end--; # the index2res script by RMosca can be used
    $pdbid = lc($pdbid);
    my $pdbfilepath=$pdbmirror."pdb".$pdbid.".ent";
    
    ## $ini[1] = first residue number | $ini[2] = chain  | $ini[3] = first residue name
    ## $end[1] = last residue number | $end[2] = chain  | $end[3] = last residue name
    
    my @ini = split(/\s+/,`/aloy/data/programs/rosa/bin/index2res $pdbfilepath $chain $index_ini`);
    #print "$pdbfilepath\n";
    #print "$chain\n";
    #print "$index_ini\n";
    #print "$index_end\n";
    my @end = split(/\s+/,`/aloy/data/programs/rosa/bin/index2res $pdbfilepath $chain $index_end`);
 
    my $outfilename=$fields[0]."_".$fields[1].".pdb";
    my $stringcommand = "\"chain $ini[2] and resi $ini[1]:$end[1]\"";
    
    #print "$ini[2] $end[1]\n";
    
    system("/aloy/data/programs/rosa/bin/pdbselect -o strs/$outfilename $stringcommand $pdbfilepath");
  }
}






