#!/usr/bin/env perl
#
#
#
use strict;
use warnings;
use List::MoreUtils qw(uniq); # uniq, for eliminating duplicated entries in an array.
use List::Compare; #  $lc = List::Compare->new(\@Llist, \@Rlist); @intersection = $lc->get_intersection;

##### loading the Target Proteins vs PFAM scanpfam output files
# my @phosscanpfam=</aloy/scratch/malonso/pphosphatase/RPache_approach/fastas/*pfamscan.out>; # path to scanpfam output files
# my @phosscanpfam=</home/malonso/phd/kinome/hpk/uniprotsearch/phosphatome/pfamscan/fastas/*pfamscan.out>; # path to scanpfam output files
my @phosscanpfam=</aloy/scratch/malonso/pphosphatase/139HPP_folder/pfamscanout_EC_PhBase_merged/fastas/*pfamscan.out>; # path to scanpfam output files

my %PhosPfam=(); # this hash contain the assigned PFAM domains for each phosphatase
foreach my $file (@phosscanpfam){
  my $key; my @fields=(); my @pfamids=();
  ## taking %PhosPfam keys (AC) from each path/filename
  $file =~ /(\w+)\.fasta\.pfamscan\.out$/;
  $key = $1;
  if(-s $file){
    open(F,$file) or die;
    while(<F>){
      chomp;
      #fields: sp|A4D256|CC14C_HUMAN DSPc  3.2e-15 ? 316 443 PF00782.13
      @fields = split ("\t",$_);
      #print "$key\t$fields[6]\t$fields[2]\n";
      #$PhosPfam{$key}{$fields[6]}=$fields[2];
      $PhosPfam{$key}{$fields[6]}=[$fields[2],$fields[4],$fields[5]];
    }
    close(F);
  }else{
    $PhosPfam{$key}{"-"}="-";
  }
##print "$_ @{$PhosPfam{$_}}\n" foreach (sort keys %PhosPfam);
}
print ".... done loading the scanpfam output files\n";
#####

##### loading the PDB vs PFAM scanpfam output files
my @pdbscanpfam=</aloy/home/malonso/kinase_proj/PDB_vs_PFAM/fastas/*pfamscan.out>; # path to scanpfam output files
print ".... done loading the paths of output files PDB scanPFAM\n";
my %PDBPfam=(); # this hash contain the assigned PFAM domains for each pdb chain
foreach my $file (@pdbscanpfam){
  my $key; my @fields=(); my @pfamids=();
  ## taking %PDBPfam keys (PDBid_chain) from each path/filename
  $file =~ /(\w+)\.fasta\.pfamscan\.out$/;
  $key = $1;
  if(-s $file){
    open(F,$file) or die;
    while(<F>){
      chomp;
      #fields: pdb_chain DSPc  3.2e-15 ? 316 443 PF00782.13
      @fields = split ("\t",$_);
      #$PDBPfam{$key}{$fields[6]}=$fields[2];
      $PDBPfam{$key}{$fields[6]}=[$fields[2],$fields[4],$fields[5]];
    }
    close(F);
  }else{
    $PDBPfam{$key}{"-"}="-";
  }
##print "$_ @{$PDBPfam{$_}}\n" foreach (sort keys %PDBPfam);
}
print ".... done loading in hash the PDB vs PFAM scanpfam output files\n";
#####

######
open (OUT,">139HPP_ac-pfam-pdb.mapping")or die;
my @intersection;
print ".... starting Phosphatase <-> PFAM <-> PDB mapping\n";
foreach my $phosAC (keys %PhosPfam){
  my @intersection=(); my $intersection_flag=0;
  my @phosdom = keys %{$PhosPfam{$phosAC}};
  
  # checking if there is at least one PFAM domain assigned to the current phsophatase
  if($phosdom[0] ne "-"){
    
    foreach my $pdbID (keys %PDBPfam){
      my @pdbdom=keys %{$PDBPfam{$pdbID}};
   
      # checking if there is at least one PFAM domain assigned to the current pdb_chain
      if($pdbdom[0] ne "-"){
        my $lc = List::Compare->new('--unsorted',\@phosdom,\@pdbdom);
        @intersection = $lc->get_intersection;
        
        # checking if there is at least one shared PFAM domain betw. current pdb_chain and phsophatase
        if(@intersection>=1){
          $intersection_flag++;
          #print OUT "$phosAC\t$protpfam_aln\t$pfamshareddom\t$pfampdb_aln\t$pdbID\n" foreach my $pfamshareddom (@intersection){};
          foreach my $pfamshareddom(@intersection){
            my $protpfam_aln=join("\t",@{$PhosPfam{$phosAC}{$pfamshareddom}});
            my $pfampdb_aln=join("\t",@{$PDBPfam{$pdbID}{$pfamshareddom}});
            print OUT "$phosAC\t$protpfam_aln\t$pfamshareddom\t$pfampdb_aln\t$pdbID\n";
          }
          #print "$phosAC $pdbID @intersection \n";
        }else{
          ## may be you want to do something if there's no intersection PFAM domains betw. current pdb_chain and phsophatase
          #foreach my $phosppfam (@phosdom){
          #  my $protpfam_aln=join("\t",@{$PhosPfam{$phosAC}{$phosppfam}});
          #  print OUT "$phosAC\t$protpfam_aln\t$phosppfam\t-\n";
          #}
        }
      }else{
        # may be you want to do something if there's no PFAM domain assigned to the current pdb_chain
      }
    }
      if($intersection_flag==0){
        foreach my $phosppfam (@phosdom){
        my $protpfam_aln=join("\t",@{$PhosPfam{$phosAC}{$phosppfam}});
        print OUT "$phosAC\t$protpfam_aln\t$phosppfam\t-\n";
        }
      }
    
  }else{
    # may be you want to do something if there's no PFAM domain assigned to the current phsophatase
    print OUT "$phosAC\t-\n";
  }
  
}


