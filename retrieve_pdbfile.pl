#!/usr/bin/env perl
#
# retrieving PDB files ferom the local mirror
#
use strict;
use warnings;
use List::MoreUtils qw(uniq);

my $pdbmirror= "/aloy/data/dbs/pdbmirror/structures/";

if(-e $ARGV[0]){
  open(F,$ARGV[0]) or die;
  my @pdbids=<F>;
  chomp(@pdbids);
  @pdbids = uniq(map(lc($_),@pdbids));
  close (F);
  system ("mkdir retrievedpdbs");
  foreach (@pdbids){
    if ($_ =~ /[\w|\d]{4}/){
      my $pdbfilepath=$pdbmirror."pdb".$_.".ent";
      system("cp $pdbfilepath retrievedpdbs/");
    }else{
      print "is $_ a PDB Id ? \n";
    }
  }
}else{print "provide a file with PDB Ids\n";}

