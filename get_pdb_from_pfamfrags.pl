#!/usr/bin/env perl
#
#
#
use strict;
use warnings;


my (@bestmods);
my $pdbmirror= "/aloy/data/dbs/pdbmirror/structures/";


###
# A4D256_PF00782_316-443  1ohc_A  1 128 201 328 97.7  100.0 36.8  4e-72 2.5 X-RAY
#
open(F,$ARGV[0]) or die; # bestmodels file for the 167 hpp domains (hpp167domains.bestmodels_v2)
@bestmods=<F>;
chomp(@bestmods);
close(F);
###

foreach (@bestmods){
  my @fields = split("\t",$_);
  if(defined $fields[1] && $fields[6]>=99 && $fields[7]>=99){ # if the model has 100% SI and QCov
    my ($pdbid,$chain) = split("_",$fields[1]);
    my ($inires,$endres) = ($fields[4],$fields[5]);
    my $pdbfilepath=$pdbmirror."pdb".$pdbid.".ent";
    #print "$pdbfilepath\n";
    
    ## open and read the PDB file 
    my $outfilename=$fields[0]."_".$fields[1].".pdb";
    open(PDB,$pdbfilepath) or die;
    open(OUTFILE,">$outfilename") or die;
    #print "$outfilename\t$pdbid,$chain,$inires,$endres\n";
    while(<PDB>){
      my @pdbfields = split("",$_); # store the current ATOM line in an array
      my $resnumb=join("",@pdbfields[22 .. 25]); # retrieve the current residue number from the PDB file
      if(/^ATOM/ && $pdbfields[21] eq $chain && $resnumb>=$inires && $resnumb<=$endres){
         print OUTFILE $_; 
      }elsif(/^HEADER/ || /^TITLE/|| /^END/){
         print OUTFILE $_;
      }
    }
    close(PDB);
    close(OUTFILE);
    ## 
  }
}







