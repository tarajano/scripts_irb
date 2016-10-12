#!/usr/bin/env perl
#
# created on: 16/Dec/2011 at 12:24 by M.Alonso
#
# Just computing the number of substrtes per HPK/HPK Family
# and generating the histograms with R.
#
# The histograms will be created in the working directory.
#
#
#


#use DBI;
use strict;
use warnings;
use LoadFile;
use List::MoreUtils qw(uniq);
use Statistics::R;

my ($pk, $subs, $R);

my (@fields, @subs_per_hpkfam, @subs_per_hpk);

my (%hpks_class,%pk_subs, %hpk_fams);

my %hpkfam_data; ## {pkfam}{pk}=[[ppis ACs],[subs ACs]]

##############################
## Loading HPKs classification and HPKs per family
foreach (File2Array("/home/malonso/phd/kinome/hpk/531_hpkd_G_F_SF_N_ID_ACcanon_ACisof_COORDs.tab")){
  @fields = splittab($_);
  if($fields[3] !~ /\~/ && $fields[4] ne "NA"){
    $hpks_class{$fields[5]}=[@fields[0..4]]; ## {AC}=[G F SF NAME UniprotID]
    push(@{$hpk_fams{join("_", @fields[0..1])}}, $fields[5]); ## {pkfam}=[ACs]
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
}
## Making substrates uniq for each PK.
foreach(keys %pk_subs){
  @fields = uniq(@{$pk_subs{$_}});
  @{$pk_subs{$_}}=@fields;
  ## Storing the number of substrates for latter plotting
  push(@subs_per_hpk, scalar(@fields));
  printf ("%d\n", scalar(@fields));
}
##############################

##############################
## Plotting the histogram of substrates per human kinase
$R = Statistics::R->new(r_bin => "/usr/bin/R");
$R->set( 'subs_per_hpk', \@subs_per_hpk );
$R->run( q`png("hist_of_subs_per_hpk.png")`);
$R->run( q`hist(subs_per_hpk, breaks=100, col="green", main="Substrates for human kinases", xlab="Number of substrates")`);
$R->run( q`dev.off()`);
##############################


##############################
## Collecting substrates per pk family
foreach my $fam (keys %hpk_fams){
  foreach my $pk ( @{$hpk_fams{$fam}} ){
    if(exists $pk_subs{$pk}){
      push (@{$hpkfam_data{$fam}}, @{$pk_subs{$pk}});
    }
  }
}

## Making substrates uniq for each PK family
foreach(keys %hpkfam_data){
  @fields = uniq(@{$hpkfam_data{$_}});
  @{$hpkfam_data{$_}}=@fields;
  ## Storing the number of substrates for latter plotting
  push(@subs_per_hpkfam, scalar(@{$hpkfam_data{$_}}));
}
##############################

##############################
## Plotting the histogram of substrates per human kinase family
$R->set( 'subs_per_hpkfam', \@subs_per_hpkfam );
$R->run( q`png("hist_of_subs_per_hpkfams.png")`);
$R->run( q`hist(subs_per_hpkfam, breaks=100, col="purple", main="Substrates for human kinase families", xlab="Number of substrates")`);
$R->run( q`dev.off()`);
##############################







