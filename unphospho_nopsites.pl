#!/usr/bin/env perl
#
# created on: 27/Apr/2011 by M.Alonso
#

use strict;
use diagnostics -verbose;
use warnings;
use LoadFile;
use Fasta2Hash;
use List::MoreUtils qw{uniq};

my @files;
my @psites;
my ($seq,$Npsite,$Cpsite);

###
## Loading non-p+lated,non-redundant human proteome
print "Loading non-p+lated,non-redundant human proteome\n";
my @fastafile = File2Array("/aloy/home/malonso/phd_proj_dbs/uniprot_2010_09/unphospho_hs_proteome/unphospho_proteome_hs.fasta.nr100");
my %fasta=Fasta2Hash(@fastafile);
###

###
## Loading p+sites in integratedphosphodb
print "Loading p+sites in integratedphosphodb\n";
foreach(File2Array("/aloy/scratch/malonso/working_on_phosphoDBs/integratedphosphodb_genpssm/integratedphosphodb_pevents_per_pk.tab")){
  ## PK Subs Res Site Seq
  @files = split("\t",$_);
  push(@psites,$files[4]);
}
@psites = uniq(@psites);
###

###
## Deleting from %fasta those entries that contain a known p+site
print "Deleting from %fasta those entries that contain a known p+site\n";
foreach my $key (keys %fasta){
  $seq = $fasta{$key};
  
  foreach my $psite (@psites){
    ### Processing N,C-terminals p+sites
    if($psite =~ /-/){
      if($psite =~ /^-/){
        ## N-term
        $Npsite = $psite;
        $Npsite =~ s/-//g;
        if($seq =~ /^$Npsite/){
          print "$psite\n";
          delete $fasta{$key};
          next;
        }
      }elsif($psite =~ /-$/){
        ## C-term
        $Cpsite = $psite;
        $Cpsite =~ s/-//g;
        if($seq =~ /$Cpsite$/){
          print "$psite\n";
          delete $fasta{$key};
          next;
        }
      }
      next;
    }
    ## Processing rest of p+sites 
    if($seq =~ /$psite/){
      delete $fasta{$key};
      next;
    }
  }
}
###

###
## Printing sequences that left
open(O,">unphospho.fasta");
foreach my $key (keys %fasta){
  print O "$key\n$fasta{$key}\n";
}
close(O);
###



