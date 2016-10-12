#!/usr/bin/env perl
#
# created on: 01/Dec/2011 at 15:45 by M.Alonso
#
# This script computes and barplots for each HPK / HPKFam
# the number of overlapping proteins between the corresponding sets
# of substrates and PPI partners.
#
use strict;
use warnings;
use LoadFile;
use List::MoreUtils qw(uniq);
use List::Compare qw(get_intersection);
use Statistics::R;

my ($pk, $subs, $partners, $overlap, $R);

my (@fields,@overlap);

my (%hpks_class,%pk_subs,%pkfam_subs,%pk_ppis,%pkfam_ppis,%hpk_fams,%map_pkAC2fam);
my %hash; ## {uniprotID}=[$partners-$overlap, $overlap, $subs-$overlap, summation]

##############################
## Loading HPKs classification and HPKs per family
foreach (File2Array("/home/malonso/phd/kinome/hpk/531_hpkd_G_F_SF_N_ID_ACcanon_ACisof_COORDs.tab")){
  @fields = splittab($_);
  if($fields[3] !~ /\~/ && $fields[4] ne "NA"){
    $hpks_class{$fields[5]}=[@fields[0..4]]; ## {AC}=[G F SF NAME UniprotID]
    push(@{$hpk_fams{join("_", @fields[0..1])}}, $fields[5]); ## HPKs per family
    $map_pkAC2fam{$fields[5]}=join("_", @fields[0..1]);
  }
}
##############################

##############################
# Loading known substrates for each HPK.
# Treating isoforms ACs as canonical.
foreach(File2Array("/home/malonso/phd/kinome/hpk/working_on_phosphoDBs/integratedphosphodb_genpssm/integratedphosphodb_pevents_per_pk.tab")){
  @fields = splittab($_);
  $pk = $fields[0];
  @fields = splitdash($fields[1]);
  $subs = $fields[0];
  ## Storing substrates per HPK
  push(@{$pk_subs{$pk}}, $subs);
  ## Storing substrates per HPK Family
  push( @{$pkfam_subs{$map_pkAC2fam{$pk}}}, $subs);
}
## Making substrates uniq for each PK.
foreach(keys %pk_subs){
  @fields = uniq(@{$pk_subs{$_}});
  @{$pk_subs{$_}}=@fields;
}
## Making substrates uniq for each PK Family.
foreach(keys %hpk_fams){
  @fields = uniq(@{$hpk_fams{$_}});
  @{$hpk_fams{$_}}=@fields;
}
##############################

##############################
## Loading PPI partners of each HPK.
my @sif_files = </aloy/scratch/malonso/test/hpk_ppidb_201111/hpks_sif_files/*.neighb>;
foreach my $file (@sif_files){
  ## Next if file is empty (i.e. no PPI partners available).
  next if (-z $file);
  
  @fields = split("/", $file);
  @fields = splitdot($fields[-1]);
  $pk = $fields[0];
  ## Loading SIF file and retrieving 1st neighbours
  foreach my $ppi_pair (File2Array($file)){
    @fields = splittab($ppi_pair);
    ## Storing 1st neighbors for PK as well as for PKFams
    if($fields[0] eq $pk){
      push(@{$pk_ppis{$pk}}, $fields[1]);
      push( @{$pkfam_ppis{$map_pkAC2fam{$pk}}}, $fields[1]);
    }elsif($fields[1] eq $pk){
      push(@{$pk_ppis{$pk}}, $fields[0]);
      push( @{$pkfam_ppis{$map_pkAC2fam{$pk}}}, $fields[0]);
    }
  }
}
## Making neighbours uniq of each PK.
foreach(keys %pk_ppis){
  @fields = uniq(@{$pk_ppis{$_}});
  @{$pk_ppis{$_}}=@fields;
}
## Making neighbours uniq of each PKFam.
foreach(keys %pkfam_ppis){
  @fields = uniq(@{$pkfam_ppis{$_}});
  @{$pkfam_ppis{$_}}=@fields;
}
##############################

##############################
## Computing overlapping set between ppi-partners and
## substrates of independet PKs
foreach my $ac (keys %hpks_class){
  if(exists $pk_subs{$ac} && exists $pk_ppis{$ac}){
    my $list_compare = List::Compare->new(\@{$pk_subs{$ac}}, \@{$pk_ppis{$ac}});
    $overlap = scalar($list_compare->get_intersection);
    $partners=scalar(@{$pk_ppis{$ac}});
    $subs=scalar(@{$pk_subs{$ac}});
    
    ## Store if there is at least one protein overlap
    if($overlap > 0){
      ## {uniprotID}=[$partners-$overlap, $overlap, $subs-$overlap, summation]
      $hash{$hpks_class{$ac}[4]}=[$partners-$overlap, $overlap, $subs-$overlap,  (($partners-$overlap)+ $overlap + ($subs-$overlap))];
    }
  }
}

## Sorting and printing to file
open(O,">HPK_overlap_ppi_substrates.tab") or die;
printf O ("%s\n", join("\t", qw(kinase ppi-partners overlap_ppi-partners-substrates substrates) ) );
foreach (sort { $hash{$b}[3] <=> $hash{$a}[3]} keys %hash){
  printf O ("%s\n", join("\t", $_,@{$hash{$_}}[0..2]) );
}
close(O);
##############################

##############################
## Computing overlapping set between ppi-partners and
## substrates of HPK families
%hash=();
foreach my $fam (keys %hpk_fams){
  if(exists $pkfam_subs{$fam} && exists $pkfam_ppis{$fam}){
    my $list_compare = List::Compare->new(\@{$pkfam_ppis{$fam}}, \@{$pkfam_subs{$fam}});
    $overlap = scalar($list_compare->get_intersection);
    $partners=scalar(@{$pkfam_ppis{$fam}});
    $subs=scalar(@{$pkfam_subs{$fam}});
    
    ## Store if there is at least one protein overlap
    if($overlap > 0){
      ## {uniprotID}=[$partners-$overlap, $overlap, $subs-$overlap, summation]
      $hash{$fam}=[$partners-$overlap, $overlap, $subs-$overlap,  (($partners-$overlap)+ $overlap + ($subs-$overlap))];
    }
  }
}

## Sorting and printing to file
open(O,">HPKFam_overlap_ppi_substrates.tab") or die;
printf O ("%s\n", join("\t", qw(kinase-fam ppi-partners overlap_ppi-partners-substrates substrates) ) );
foreach (sort { $hash{$b}[3] <=> $hash{$a}[3]} keys %hash){
  printf O ("%s\n", join("\t", $_,@{$hash{$_}}[0..2]) );
}
close(O);
##############################

##############################
## Barplotting
$R = Statistics::R->new(r_bin => "/usr/bin/R");
$R->start();
$R->run(q`library(pgirmess)`); ##  pgirmess::pclig for computing proportions on row totals

## Barplotting overlaps for independent kinases
$R->run(qq`myd <- read.table("HPK_overlap_ppi_substrates.tab", head=T,row.names=1)`);
$R->run(qq`png("HPK_overlap_ppi_substrates.png", width=20, height=20, units = 'cm', res=600, pointsize=8)`);
$R->run(q`myd[ ,c(1,2)]  <- myd[ ,c(2,1)]`); ## swapping columns values before plotting
$R->run(q`colnames(myd)[c(1,2)] <- colnames(myd)[c(2,1)]`); ## swapping columns names before plotting
$R->run(q`par(xpd=T, mar=par()$mar+c(0,0,0,0))`);
$R->run(q`mp <- barplot(t(myd),  space=0.7, cex.names=0.001, col=c("green","red","blue"), border=NA)`);
$R->run(q`text(mp, par("usr")[3] - 0.025, srt = 90, adj = 1, labels = c(rownames(myd)), xpd = TRUE, font = 2, cex=0.20)`);
$R->run(q`mtext('Overlap between partners and substrates sets',side=3, line=1.7, cex=2)`);
$R->run(q`mtext('Human Kinases',side=1,line=3.8, cex=1.3)`);
$R->run(q`mtext('Number of partners and substrates',side=2,line=3.2, cex=1.3)`);
$R->run(q`legend(160, 300, names(myd), cex=1.2, fill=c("green","red","blue"), border="gray", bty="n")`);
$R->run(q`dev.off()`);

## Barplotting overlaps percentages for independent kinases
$R->run(qq`myd <- read.table("HPK_overlap_ppi_substrates.tab", head=T,row.names=1)`);
$R->run(qq`png("HPK_overlap_prct_ppi_substrates.png", width=20, height=20, units = 'cm', res=600, pointsize=8)`);
$R->run(q`myd[ ,c(1,2)]  <- myd[ ,c(2,1)]`); ## swapping columns values before plotting
$R->run(q`colnames(myd)[c(1,2)] <- colnames(myd)[c(2,1)]`); ## swapping columns names before plotting
$R->run(q`par(xpd=T, mar=par()$mar+c(0,0,0,0))`);
$R->run(q`mp <- barplot(t(pclig(myd)*100),  space=0.7, cex.names=0.001, col=c("green","red","blue"), border=NA)`);
$R->run(q`text(mp, par("usr")[3] - 0.025, srt = 90, adj = 1, labels = c(rownames(myd)), xpd = TRUE, font = 2, cex=0.20)`);
$R->run(q`mtext('Overlap between partners and substrates sets',side=3, line=1.7, cex=2)`);
$R->run(q`mtext('Human Kinases',side=1,line=3.8, cex=1.3)`);
$R->run(q`mtext('Percent',side=2,line=3.2, cex=1.3)`);
$R->run(q`dev.off()`);
$R->run(q`rm(myd)`);


## Barplotting overlaps for kinases families
$R->run(qq`myd <- read.table("HPKFam_overlap_ppi_substrates.tab", head=T,row.names=1)`);
$R->run(qq`png("HPKFam_overlap_ppi_substrates.png", width=20, height=20, units = 'cm', res=600, pointsize=8)`);
$R->run(q`myd[ ,c(1,2)]  <- myd[ ,c(2,1)]`); ## swapping columns values before plotting
$R->run(q`colnames(myd)[c(1,2)] <- colnames(myd)[c(2,1)]`); ## swapping columns names before plotting
$R->run(q`par(xpd=T, mar=par()$mar+c(0,0,0,0))`);
$R->run(q`mp <- barplot(t(myd),  space=0.7, cex.names=0.001, col=c("green","red","blue"), border=NA)`);
$R->run(q`text(mp, par("usr")[3] - 0.025, srt = 90, adj = 1, labels = c(rownames(myd)), xpd = TRUE, font=2, cex=0.5)`);
$R->run(q`mtext('Overlap between partners and substrates sets',side=3, line=1.7, cex=2)`);
$R->run(q`mtext('Human Kinases Families',side=1,line=3.8, cex=1.3)`);
$R->run(q`mtext('Number of partners and substrates',side=2,line=3.2, cex=1.3)`);
$R->run(q`legend(68, 1200, names(myd), cex=1.2, fill=c("green","red","blue"), border="gray", bty="n")`);
$R->run(q`dev.off()`);

## Barplotting overlaps percentages for kinases families
$R->run(q`pclig(myd)`);
$R->run(q`png("HPKFam_overlap_prct_ppi_substrates.png", width=20, height=20, units = 'cm', res=600, pointsize=8)`);
$R->run(q`par(xpd=T, mar=par()$mar+c(0,0,0,0))`);
$R->run(q`mp <- barplot( t(pclig(myd)*100), space=0.7, cex.names=0.001, col=c("green","red","blue"), border=NA  )`);
$R->run(q`text(mp, par("usr")[3] - 0.025, srt = 90, adj = 1, labels = c(rownames(myd)), xpd = TRUE, font=2, cex=0.5)`);
$R->run(q`mtext('Overlap between partners and substrates sets',side=3, line=1.7, cex=1.7)`);
$R->run(q`mtext('Human Kinases Families',side=1,line=3.8, cex=1.3)`);
$R->run(q`mtext('Percent',side=2,line=3.2, cex=1.3)`);
$R->run(q`dev.off()`);
$R->run(q`rm(myd)`);


$R->stop();
##############################




