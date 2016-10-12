#!/usr/bin/env perl
#
# created on: 12/Sep/2011 at 14:00 by M.Alonso
#
# Getting the number of shared psites by each pair of
# input kinases.
#
#
use strict;
use warnings;
use LoadFile;
use List::MoreUtils qw(uniq);

my $queryFile=$ARGV[0];
die "\nPlease, provide a file with a list of query ACs\n\n" unless(-e $queryFile && -s $queryFile);

my $counter=0;
my ($k1,$k2,$qk1,$qk2);

my (@fields, @query_ac_pairs, @query_ac_pairs_shared);


##############################
## Load query ACs
@fields = File2Array($queryFile);
## Eliminating possible duplicated ACs.
@fields = sort(uniq(@fields));

for (my $i=0; $i <= $#fields; $i++){
  foreach(my $ii=$i+1; $ii <= $#fields; $ii++){
    push(@query_ac_pairs,[$fields[$i],$fields[$ii]]);
  }
}
#print "@{$_}\n" foreach(@query_ac_pairs);
##############################

##############################
## Load shared psites.
foreach my $line (File2Array("/aloy/scratch/malonso/working_on_phosphoDBs/integratedphosphodb_genpssm/allpks/per_pks/pks_shared_psites_substrates.tab")){
  ## pk1	pk2	pk1psites	pk2psites	pk1substs	pk2substs	sharedpsites	sharedsubts
  @fields = splittab($line);
  ($k1,$k2)=@fields[0..1];
  foreach(@query_ac_pairs){
    ($qk1,$qk2)=@{$_};
    if($k1 eq $qk1 && $k2 eq $qk2 || $k1 eq $qk2 && $k2 eq $qk1){
      push(@query_ac_pairs_shared,$line);
      $counter++;
    }
    ## last if all query pairs have been found.
    last if($counter == scalar(@query_ac_pairs));
  }
}
##############################

##############################
## Printing
printf ("#%s\n", join("\t",qw(pk1 pk2 pk1psites pk2psites pk1substs pk2substs sharedpsites sharedsubts)));
print "$_\n" foreach(sort @query_ac_pairs_shared);
##############################

