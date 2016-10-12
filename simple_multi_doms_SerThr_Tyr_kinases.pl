#!/usr/bin/env perl
#
# created on: 05/Mar/2012 at 14:07 by M.Alonso
#
# Counting how many of the Ser/Thr and Tyr kinases are single | multi domains.
#
#
#


#use DBI;
#use Statistics::R;
use strict;
use warnings;
use LoadFile;
use List::MoreUtils qw(uniq);
use List::Compare qw(get_intersection);

my ($catspecif, $ac, $DomComposition);
my @fields;
my %hpk_CatSpecif; ## {stpk|ypk}=[ACs]
my %hpk_DomComposition; ## {single|multi}=[ACs]

###############################
## Loading kinases classification given their catalytic specificity Ser/Thr OR Tyr.
foreach (File2Array("/home/malonso/phd/kinome/hpk/ec2hpk/map_ec2uniprot.out",1)){
  ## AAK1_HUMAN   AAK1  Q2M2I8  2.7.11.1  stpk  DE:
  @fields = splittab($_);
  next unless (defined $fields[3]);
  if($fields[4] eq "stpk" || $fields[4] eq "ypk" ){
    $catspecif = $fields[4];
    @fields = splitdash($fields[2]);
    $ac = $fields[0];
    ## {ac}=stpk|ypk
    push(@{$hpk_CatSpecif{$catspecif}}, $ac);
  }
}
###############################

###############################
## Loading kinases classification given their domain composition (single/multi domain)
foreach (File2Array("/home/malonso/phd/kinome/hpk/hpk_Pfam/pfam_results.tab")){
  ## AGC_AKT_AKT1   P31749  multiple  PF00069.18  Pkinase   6.7e-75   150   408
  @fields = splittab($_);
  ## {ac}=single|multiple
  push(@{$hpk_DomComposition{$fields[2]}}, $fields[1]);
}

foreach (keys %hpk_DomComposition){
  @fields = uniq(@{$hpk_DomComposition{$_}});
  $hpk_DomComposition{$_} = [@fields];
}
###############################

###############################
## Counting... 
my ($lc, $intersection, $intersection_pct, $total);
foreach $catspecif (keys %hpk_CatSpecif){
  foreach $DomComposition (keys %hpk_DomComposition){
    $lc = List::Compare->new(\@{$hpk_CatSpecif{$catspecif}},\@{$hpk_DomComposition{$DomComposition}});
    $intersection = scalar($lc->get_intersection());
    $intersection_pct = sprintf("%.2f", $intersection*100/scalar(@{$hpk_CatSpecif{$catspecif}}));
    $total = scalar @{$hpk_CatSpecif{$catspecif}};
    print "$catspecif $total $DomComposition $intersection\/$total ($intersection_pct %)";
    #print "$intersection / scalar(@{$hpk_CatSpecif{$catspecif}}) $intersection_pct\n";
    print "\n";
  }
}
###############################




