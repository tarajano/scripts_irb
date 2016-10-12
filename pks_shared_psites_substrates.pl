#!/usr/bin/env perl
#
# Adapted from pkfams_shared_psites.pl. (Created on: 12/May/2011 by M.Alonso)
#
# Created on Mon Sep 12 12:00:54
# 
# Collecting shared PSites || Substrates among PKs
#
# INPUT:
#
# OUTPUT:
#
#

use strict;
use warnings;
use LoadFile;
use List::Compare; # $intersection = List::Compare->new(\@Llist, \@Rlist); @intersection = $intersection->get_intersection;
use List::MoreUtils qw(uniq);

my ($fastafile,$pkfam_name,$psite,$pkfampair);

my (@fields,@intersection,@pkfams_shared_psites);

my (%pk_psites, %pk_substrates);

my %pk_pair_shared_psites_substs; ## {pk1 pk2}=[psitesPK1 psitesPK2 substsPK1 substsPK2 sharedPSites sharedSubsts]

##############################
## Collecting PSites
## O00141 O14920 181 S SLCTSFVGT
print "Loading psites\n";
foreach(File2Array("/aloy/scratch/malonso/working_on_phosphoDBs/integratedphosphodb_genpssm/integratedphosphodb_pevents_per_pk.tab")){
  @fields=split("\t",$_);
  push(@{$pk_psites{$fields[0]}},join("@",@fields[1..3]));
  push(@{$pk_substrates{$fields[0]}},$fields[1]);
}
##############################

##############################
## Making non redundant list of psites and substrates
foreach(keys %pk_psites){
  $pk_psites{$_}=[uniq(@{$pk_psites{$_}})];
  $pk_substrates{$_}=[uniq(@{$pk_substrates{$_}})];
}
##############################


##############################
## Retrieving number of shared psites & substrates among pks
print "Retrieving number of shared psites among pks\n";
my ($k1,$k2);
foreach $k1 (sort {$a cmp $b} keys %pk_psites){
  print "  $k1\n";
  foreach $k2 (sort {$a cmp $b} keys %pk_psites){
    next if ($k1 eq $k2);
    my $pair = join("\t",$k1,$k2);
    ## counting shared psites and substrates
    my $psites_intersection = List::Compare->new('--unsorted', \@{$pk_psites{$k1}},\@{$pk_psites{$k2}});
    my $substs_intersection = List::Compare->new('--unsorted', \@{$pk_substrates{$k1}},\@{$pk_substrates{$k2}});
    ## {pk1 pk2}=[psitesPK1 psitesPK2 substsPK1 substsPK2 sharedPSites sharedSubsts]
    $pk_pair_shared_psites_substs{$pair}=[scalar(@{$pk_psites{$k1}}),scalar(@{$pk_psites{$k2}}), scalar(@{$pk_substrates{$k1}}), scalar(@{$pk_substrates{$k2}}), scalar($psites_intersection->get_intersection), scalar($substs_intersection->get_intersection)];
  }
  delete $pk_psites{$k1};
}
##############################

##############################
## Printing PKFam pairs and number of shared psites & substrates among pks
open(PS,">pks_shared_psites_substrates.tab") or die;
printf PS ("#%s\n", join("\t",qw(pk1 pk2 pk1psites pk2psites pk1substs pk2substs sharedpsites sharedsubts)));
foreach(sort {$a cmp $b} keys %pk_pair_shared_psites_substs){
  ## priting shared psites
  print PS "$_\t"; printf PS ("%s\n", join("\t",@{$pk_pair_shared_psites_substs{$_}}));
}
close(PS);

##############################




