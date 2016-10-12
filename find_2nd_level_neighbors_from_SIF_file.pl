#!/usr/bin/env perl
#
# Created on: 30/Nov/2011 by M.Alonso
#
# To building a 2nd level interactome network starting from seed proteins.
#
# Input:
#   - A file with a tab delimited interactome.
#       + AC1 AC2
#   - A file with a list of seed proteins, or a single AC
#
# Output:
#   - Tab delimited files with the 1st | 2nd level interactome of each seed protein.
#
# Usage:
# ./thisscript interactomelevel [UniProtAC.list | UniProtAC] /path/to/interactomefile
# 
# E.g.L
# ./thisscript 2 UniProtAC.list /pathto/interactomefile.tab
# 
# 


use strict;
use warnings;
use LoadFile;
use List::MoreUtils qw(uniq);

my $uniprotac;
my @fields;
my @human_ppi; ## [[p1, p2],[p1, p4]]

#############################
### Simple checking for input arguments
unless(defined $ARGV[0] && defined $ARGV[1] && defined $ARGV[2]){
  print "  Usage:\n  ./thisscript interactomelevel [UniProtAC.list | UniProtAC] /path/to/interactomefile\n\n\n";
  die;
}
#############################

#############################
### Getting neighbours level [1 or 2 levels].
my $interactomelevel = $ARGV[0];
die "Please enter a valid number for the neighboors level [1|2]\n" unless($interactomelevel==1 || $interactomelevel==2);
#############################

#############################
### Loading interactome from file.
###
my $interactomefile = $ARGV[2];
foreach (File2Array($interactomefile)){
  @fields = splittab($_);
  push(@human_ppi, [@fields]);
}
#############################

#############################
### 
### 
### 

### Create output directory
mkdir("ppi_files") unless (-d "ppi_files");

if(-e $ARGV[1] && $interactomelevel==1){
  foreach $uniprotac (File2Array($ARGV[1])){ neighbours_1st_level($uniprotac); }
}elsif(-e $ARGV[1] && $interactomelevel==2){
  foreach $uniprotac (File2Array($ARGV[1])){  neighbours_2nd_level($uniprotac); }
}elsif($interactomelevel==1){
  neighbours_1st_level($ARGV[1]);
}elsif($interactomelevel==2){
  neighbours_2nd_level($ARGV[1]);
}else{print "Did you provide valid arguments to the script\n";}
#############################

#############################
######## SUBROUTINES ######## 
#############################

#############################
sub neighbours_1st_level{
  
  my $ppi_pair;
  my $queryAC = $_[0];
  print "processing $queryAC\n";
  
  my @ppi_network;
  
  my %interactors=();
  my %sec_nodes=(); ## seed nodes for the 2nd & 3th -levels neighbourhoods
  
  ########## FIRST NEIGHBOURS
  foreach(@human_ppi){
    if( ${$_}[0] eq $queryAC || ${$_}[1] eq $queryAC ){
      $ppi_pair=jointab(sort @{$_});
      push (@ppi_network, $ppi_pair);
    }
  }
  ##########
  
  @ppi_network = uniq(@ppi_network);

  open(OUTFILE,">ppi_files/$queryAC.ppi") or die;
  print OUTFILE "$_\n" foreach (@ppi_network);
  close(OUTFILE);
}
#############################

#############################
sub neighbours_2nd_level{
  my $ppi_pair;
  my $queryAC = $_[0];
  print "processing $queryAC\n";
  
  my @ppi_network;
  my %interactors=();
  my %sec_nodes=(); ## seed nodes for the 2nd & 3th -levels neighbourhoods
  
  ########## FIRST NEIGHBOURS
  foreach(@human_ppi){
    if( ${$_}[0] eq $queryAC || ${$_}[1] eq $queryAC ){
      $ppi_pair=jointab(sort @{$_});
      push (@ppi_network, $ppi_pair);
      $sec_nodes{${$_}[0]}=1 if(${$_}[0] ne $queryAC);  ## seed nodes for 2nd-level neighbourhood
      $sec_nodes{${$_}[1]}=1 if(${$_}[1] ne $queryAC);  ## seed nodes for 2nd-level neighbourhood
    }
  }
  ##########

  ########## SECOND NEIGHBOURS
  foreach my $second_seed (keys %sec_nodes){
    foreach (@human_ppi){
      if( ${$_}[0] eq $second_seed || ${$_}[1] eq $second_seed ){
        $ppi_pair=jointab(sort @{$_});
        push (@ppi_network, $ppi_pair);
      }
    }
  }
  ##########
  
  @ppi_network = uniq(@ppi_network);

  open(OUTFILE,">ppi_files/$queryAC.ppi") or die;
  print OUTFILE "$_\n" foreach (@ppi_network);
  close(OUTFILE);
}
#############################



