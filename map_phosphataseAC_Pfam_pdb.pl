#!/usr/bin/env perl
#
#
#
use strict;
use warnings;
use List::MoreUtils qw(uniq); # uniq, for eliminating duplicated entries in an array.
use List::Compare; #  $lc = List::Compare->new(\@Llist, \@Rlist); @intersection = $lc->get_intersection;

##### loading the Phosphatome vs PFAM scanpfam output files
my @phosscanpfam=</home/malonso/phd/kinome/hpk/uniprotsearch/phosphatome/pfamscan/fastas/*pfamscan.out>; # path to scanpfam output files
my %PhosPfam=(); # this hash contain the assigned PFAM domains for each phosphatase
foreach my $file (@phosscanpfam){
  my $key; my @tmp=(); my @pfamids=();
  ## taking %PhosPfam keys (AC) from each path/filename
  $file =~ /(\w+)\.fasta\.pfamscan\.out$/;
  $key = $1;
  if(-s $file){
    open(F,$file) or die;
    while(<F>){
      chomp;
      /\s+(PF.+)$/;
      push(@tmp,$1);
    }
    @pfamids=uniq(@tmp);
    $PhosPfam{$key}=[@pfamids];
    close(F);
  }else{
    $PhosPfam{$key}=["-"];
  }
##print "$_ @{$PhosPfam{$_}}\n" foreach (sort keys %PhosPfam);
}
print ".... done loading the Phosphatome vs PFAM scanpfam output files\n";
#####

##### loading the PDB vs PFAM scanpfam output files
my @pdbscanpfam=</home/malonso/phd/kinome/hpk/uniprotsearch/PDB_fastas/fastas/*pfamscan.out>; # path to scanpfam output files
print ".... done listing the PDB vs PFAM scanpfam output files\n";
my %PDBPfam=(); # this hash contain the assigned PFAM domains for each pdb chain

foreach my $file (@pdbscanpfam){
  my $key; my @tmp=(); my @pfamids=();
  ## taking %PDBPfam keys (PDBid_chain) from each path/filename
  $file =~ /(\w+)\.fasta\.pfamscan\.out$/;
  $key = $1;
  if(-s $file){
    open(F,$file) or die;
    while(<F>){
      chomp;
      /\s+(PF.+)$/;
      push(@tmp,$1);
    }
    @pfamids=uniq(@tmp);
    $PDBPfam{$key}=[@pfamids];
    close(F);
  }else{
    $PDBPfam{$key}=["-"];
  }
##print "$_ @{$PDBPfam{$_}}\n" foreach (sort keys %PDBPfam);
}
print ".... done loading the PDB vs PFAM scanpfam output files\n";
#####

######
my @intersection;
print ".... starting Phosphatase <-> PFAM <-> PDB mapping\n";
foreach my $phoskey (keys %PhosPfam){
  my @phosdom=@{$PhosPfam{$phoskey}};
  
  # checking if there is at least one PFAM domain assigned to the current phsophatase
  if($phosdom[0] ne "-"){
    foreach my $pdbkey (keys %PDBPfam){
      my @pdbdom=@{$PDBPfam{$pdbkey}};
     
      # checking if there is at least one PFAM domain assigned to the current pdb_chain
      if($pdbdom[0] ne "-"){
        my $lc = List::Compare->new('--unsorted',\@phosdom,\@pdbdom);
        @intersection = $lc->get_intersection;
        
        # checking if there is at least one shared PFAM domain betw. current pdb_chain and phsophatase
        if(@intersection>=1){
          print "$phoskey $pdbkey @intersection\n";
        }else{
          # may be you want to do something if there's no intersection PFAM domains betw. current pdb_chain and phsophatase
        }
      }else{
        # may be you want to do something if there's no PFAM domain assigned to the current pdb_chain
      }
    }
  }else{
    # may be you want to do something if there's no PFAM domain assigned to the current phsophatase
  }
}



















