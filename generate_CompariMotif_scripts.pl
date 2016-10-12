#!/usr/bin/env perl
#
# created on: 15/Mar/2011 by M.Alonso
#
# Generating the scripts for CompariMotifs runs to be executed on the 
# PKs pairs for which it was possible to derive at least one
# PMotif by using SLiMFinder.
#
#
use Cwd;
use strict;
use warnings;
use File::Copy;

my (@fields,@pks,@pks_comparison_pairs,@scriptslist);

my $CompariMotifCommand = "python /home/malonso/programs/slimsuite/comparimotif_V3.py motifs=MOTIFs1 searchdb=MOTIFs2 resfile=OUTFILE minshare=2 minpep=3 nrmotif=T aafreq=/aloy/scratch/malonso/working_on_phosphoDBs/hprd_v9/slimfinder_hprd9/humanproteome_maat.aafreq.txt";
my $CompariMotifFolder="/aloy/scratch/malonso/working_on_phosphoDBs/integrateddbs/comparimotifs_runs/";
my $SlimFinder_runs_folder="/aloy/scratch/malonso/working_on_phosphoDBs/integrateddbs/slimfinder_runs/";
my ($pair,$pairfolder,$pk1,$pk2,$tmp_command,$CompariMotifOutput); 


########################
## Retrieving the PKs for which it was possible 
## to derive a SLimFinder Motif
print "Retrieving the PKs with derived Motifs\n";
my $cvs = `find $SlimFinder_runs_folder -name '*.cvs' `;
my @cvs = split('\n',$cvs);
foreach (@cvs){
  my $line = `sed -n '2p' $_`;
  chop($line);
  @fields = split('\t',$line);
  if($fields[12] && $fields[12] ne "-"){
    ## Fetching PKs (*) names from SliMFinder output (cvs) files
    ## (*) PKs for which at least one PMotif was derived by SlimFinder
    @fields = split("/",$_);
    @fields = split(".cvs",$fields[-1]);
    ## Getting PKs in an array
    push(@pks,$fields[0]); 
  }
}#print "$_\n" foreach(@pks);
########################

########################
## Generating comparison pairs of PKs to be submited to CompariMotifs
print "Generating comparison pairs\n";
for(my $i=0; $i<$#pks; $i++){
  for(my $ii = $i+1; $ii<=$#pks; $ii++){
    push(@pks_comparison_pairs,[$pks[$i],$pks[$ii]]);
  }
}#print "@{$_}\n" foreach(@pks_comparison_pairs);
########################

########################
## Creating the directory structures and CompariMotif scripts
print "Creating comparison pairs directories and scripts\n";
foreach(@pks_comparison_pairs){
  ## Creating folders
  ($pk1,$pk2)=@{$_};
  $pair=join("-",$pk1,$pk2);
  $pairfolder=$CompariMotifFolder.$pair;
  mkdir($pairfolder);
  ## Copying cvs files to comparison pair folder
  copy($SlimFinder_runs_folder.$pk1."/$pk1.cvs",$pairfolder);
  copy($SlimFinder_runs_folder.$pk2."/$pk2.cvs",$pairfolder);
  ## Generating script file
  my $ScriptFile=$pairfolder."/".$pair.".comparimotif";
  my $tmp_command = $CompariMotifCommand;
  $tmp_command =~ s/MOTIFs1/$pk1.cvs/;
  $tmp_command =~ s/MOTIFs2/$pk2.cvs/;
  $tmp_command =~ s/OUTFILE/$pair/;
  open(SCRIPT,">$ScriptFile") or die;
  print SCRIPT "$tmp_command";
  close(SCRIPT);
  push(@scriptslist,$ScriptFile);
}
########################

########################
## Generating the file with the list of paths to comparimotif scripts
## To be used for creating the ArrayJob 
open(O,">comparimotif.scripts.list") or die;
print O "$_\n" foreach(@scriptslist);
close(O);
########################




