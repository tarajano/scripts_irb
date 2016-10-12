#!/usr/bin/env perl
#
# created on: 14/Mar/2011 by M.Alonso
#
# Generating the directories, psites.fasta files and .slimfinder scripts for 
# running SlimFinder on the PSites from HPRDv9
# 
# INPUT FILES:
#  hprd_psite_seq_per_PK.fasta # 41mer lenght sequences of PSites
#  humanproteome_maat.fa, humanproteome_maat.aafreq.txt # human proteome file and its corresponing AA freq as calculated by SlimFinder
#
# OUTPUT: 
#  1) one folder per PK for which there is a reported PSite in HPRDv9 containing
#       - the fasta sequences of the corresponding PSites
#       - a script file for executing SlimFinder (*.slimfinder)
#  2) a file with the paths to the *.slimfinder files to be executed (use ArrayJob for this)
#
#
#
#

use strict;
use warnings;
use List::MoreUtils qw(uniq);

my $SlimFinderexe="/home/malonso/programs/slimsuite/slimfinder.py";
my $working_dir="/aloy/scratch/malonso/working_on_phosphoDBs/hprd_v9/slimfinder_hprd9/slimfinder_runs/";
my $proteomefile="/aloy/scratch/malonso/working_on_phosphoDBs/hprd_v9/slimfinder_hprd9/humanproteome_maat.fa";
my $psites_fasta_file="/aloy/scratch/malonso/working_on_phosphoDBs/hprd_v9/slimfinder_hprd9/hprd_psite_seq_per_PK_41mer.fasta";
my $slimfinder_command="python $SlimFinderexe seqin=SEQIN aafreq=$proteomefile resdir=RESDIR resfile=RESFILE musthave=MUSTHAVE termini=F wildvar=T masking=F gnspacc=F  topranks=50 walltime=1";

my ($key,$enz_folder);
my ($resdir,$resfile,$seqin);
my ($prev_enzid,$enzid,$enzac,$site,$res,$subsisoid,$musthave);

my (%psites_fasta,%tmp_psites);
my (@fields,@musthave,@slimfinder_comm_files);

#################
### Loading fasta psites.fasta file
open(F,$psites_fasta_file) or die;
while(<F>){
  chomp();
  if($_ =~ /^>(.+$)/){
    $key = $1;
    $psites_fasta{$key}="";
  }elsif(/^[A-Z]/){
    $psites_fasta{$key}=$_;
  }
}
close(F);
#################


#################
### Generating for each hpk the input files and parameters requiered for running SlimFinder
$prev_enzid="";
foreach $key (sort {$a cmp $b} keys %psites_fasta){
  ($enzid,$enzac,$site,$res,$subsisoid) = split("-",$key); #04462-O14920-705-S-04462_1
  if($enzid eq $prev_enzid || $prev_enzid eq ""){
    ## If this is the first iteration OR if still with the same enzyme
    ## of the iteration before, store its data
    $tmp_psites{$key}=$psites_fasta{$key};
    push(@musthave,$res);
    $prev_enzid = $enzid;
  }elsif($enzid ne $prev_enzid && $prev_enzid ne ""){
    ## If a new enzyme its been processed, print out previous enzyme data
    print_enzyme_data();
  }
}
print_enzyme_data();
#################


#################
## Creating the file containing the paths to
## each SlimFinder command
open(LIST,">slimfinder_comm_files.list") or die;
print LIST "$_\n" foreach(@slimfinder_comm_files);
close(LIST);
#################




########################
##### SUBROUTINES ######
########################

########################
## Printing out previous enzyme data and files.
sub print_enzyme_data{
  ## Creating output dir & file
  $resdir= $working_dir.$prev_enzid;
  system("mkdir $resdir") unless(-d $resdir);
  $resfile=$resdir."/".$prev_enzid.".cvs";
  ## Creating SEQIN (fasta) file
  $seqin=$resdir."/".$prev_enzid.".fas";
  open(O,">$seqin") or die;
  print O ">$_\n$tmp_psites{$_}\n" foreach(keys %tmp_psites);
  close(O);
  ## Eliminate duplicates in musthave residues list
  @musthave = uniq(@musthave);
  ## Create command file
  $musthave=join(",",@musthave);
  my $tmp_command = $slimfinder_command;
  $tmp_command =~ s/MUSTHAVE/$musthave/;
  $tmp_command =~ s/RESDIR/$resdir/;
  $tmp_command =~ s/RESFILE/$resfile/;
  $tmp_command =~ s/SEQIN/$seqin/;
  my $comm=$resdir."/".$prev_enzid.".slimfinder";
  open(O,">$comm") or die;
  print O "$tmp_command";
  close(O);
  ## Filling an array with the list of commands files for creating
  ## later the ArrayJob from which SlimFinder will be ran.
  push(@slimfinder_comm_files,$comm);
  
  #####
  ## Clean up data from previous enzyme
  @musthave=(); %tmp_psites=();
  ## Start loading data from current enzyme
  push(@musthave,$res);
  $tmp_psites{$key}=$psites_fasta{$key};
  $prev_enzid = $enzid;  
}
########################








