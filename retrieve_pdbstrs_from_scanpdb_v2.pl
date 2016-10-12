#!/usr/bin/env perl
#
## Due to the merging of the solutions from Blast and SSEARCH programs
## the ScanPDB output file contains duplicated solutions (same PDB, same chain)
## for a given target sequence. (see example below)
##
# ABL1 252 1fpu  A 275 251 252 252 1 252 18  269 99.6  100.0 91.6  6e-150
# ABL1 252 1fpu  A 275 251 252 252 1 252 18  269 99.6  100.0 91.6  2e-124
# ABL1 252 1fpu  B 270 246 252 247 1 252 18  264 97.6  100.0 91.5  6e-145
# ABL1 252 1fpu  B 270 246 252 247 1 252 18  264 97.6  100.0 91.5  3e-120
# ABL1 252 1iep  A 274 251 252 252 1 252 18  269 99.6  100.0 92.0  6e-150
# ABL1 252 1iep  A 274 251 252 252 1 252 18  269 99.6  100.0 92.0  2e-124
##
## With this script, based on E-value of each str/template solution, I'm eliminating 
## the redundant solutions (same PDB, same chain) for every query. 
## For achieving this I only keep the str/tmplt solution with lower E-value.
# 
# strs/tmpls are retrieved to the strs directory that will be created by the script
#
# usage:
# ./script scanpd.out.merged
# 

use strict;
use warnings;

my (@infile,@fields,@prev_fields,@non_indentical_pdbchains,@non_indentical_pdbs);
my $flag=0;

##############
## read in scanpdb output file
open(I,$ARGV[0]) or die;
@infile=<I>;
chomp(@infile);
close(I);
##############

##############
## Eliminating the redundant solutions (same PDB, same chain) for every query. 
$flag=0;
my %tmphash=();
my $line;
foreach $line (@infile){
  @fields = split("\t",$line);
  
  ## Do nothing on first line
  if($flag>0){
    ## If Query and PDB are the same of the previous record
    ## store both solutions in a tmphash{e-value}
    if($fields[0] eq $prev_fields[0] && $fields[2] eq $prev_fields[2]){
      $tmphash{$fields[15]}=$line;
      $tmphash{$prev_fields[15]}=join("\t",@prev_fields);
    }else{
      ## sort the hash by the e-value (smaller values first)
      my @keys = sort { $a <=> $b } keys %tmphash;
      ## If not empty, process the %tmphash{e-value}
      if(scalar(@keys)!=0){
        push(@non_indentical_pdbs, $tmphash{$keys[0]});
        %tmphash=();
      }else{
        push(@non_indentical_pdbs, $line);
      }
    }
  }else{$flag++;}
  @prev_fields=@fields;
}
##### processing the last entries of the scanpdb file
## sort the hash by the e-value (smaller values first)
my @keys = sort { $a <=> $b } keys %tmphash;
## If not empty, process the %tmphash{e-value}
if(scalar(@keys)!=0){
  push(@non_indentical_pdbs, $tmphash{$keys[0]});
  %tmphash=();
}else{
  push(@non_indentical_pdbs, $line);
}
##
##############

##############
#foreach(@non_indentical_pdbs){
  #print "$_\n";
#}
##############

##############
## Taking the @non_indentical_pdbs and retrieving the coordinates (strs/tmplt) for each query.
## Extracting PDBids, fetching the corresponding structures fragments from PDB DB.
##
my $pdbmirror= "/aloy/data/dbs/pdbmirror/structures/";
my $count=0;
foreach (@non_indentical_pdbs){
  $count++;
  printf("retrieving %d of %d\n",$count,scalar(@non_indentical_pdbs));
  my @fields = split("\t",$_);
  if(defined $fields[2]){
    my ($pdbid,$chain) = ($fields[2],$fields[3]);
    my ($index_ini,$index_end) = ($fields[10],$fields[11]); # getting resnumbs in PDB 
    $index_ini--; # Making the residues indexes zero-based so that
    $index_end--; # the index2res script by RMosca can be used
    $pdbid = lc($pdbid);
    my $pdbfilepath=$pdbmirror."pdb".$pdbid.".ent";
    
    ## $ini[1] = first residue number | $ini[2] = chain  | $ini[3] = first residue name
    ## $end[1] = last residue number | $end[2] = chain  | $end[3] = last residue name
    
    my @ini = split(/\s+/,`/aloy/data/programs/rosa/bin/index2res $pdbfilepath $chain $index_ini`);
    #print "$pdbfilepath\n";
    #print "$chain\n";
    #print "$index_ini\n";
    #print "$index_end\n";
    
    my @end = split(/\s+/,`/aloy/data/programs/rosa/bin/index2res $pdbfilepath $chain $index_end`);
 
    my $outfilename=$fields[0]."_".$fields[2].$fields[3].".pdb";
    my $stringcommand = "\"chain $ini[2] and resi $ini[1]:$end[1]\"";
    
    #print "$ini[2] $end[1]\n";
    
    ## create strs directory if it does not exists
    unless (-d "strs"){
      system("mkdir strs");
    }
    system("/aloy/data/programs/rosa/bin/pdbselect -o strs/$outfilename $stringcommand $pdbfilepath");
  }
}
##############



