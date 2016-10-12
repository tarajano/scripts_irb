#!/usr/bin/env perl 
#
# 
#

use strict;
use warnings;

my %bestmods_list;
my %manning_list;
my @fields;
my %pdb_org;
my $k; my $label; my $sourceorg;


# loading the bestmodels file that must include the hpkdoms without any 3D info found
# JAK1  3eyg_A  1 278 11  288 100 100 95.9  4.00E-166 1.9 X-RAY
# hpkdompdb_merged_best_models_plus_no3DinfoHPKD_si30_qc80
open(F,$ARGV[0])or die;
while(<F>){
  chomp;
  @fields = split("\t",$_);
  $bestmods_list{$fields[0]}=[@fields];
}
close(F);

# loading Manning s file
# provide the file manning_2002_TableS1_G_F_S_N.txt
# /home/malonso/phd/kinome/hpk/hpk_domains/ePKtree/manning_2002_TableS1_G_F_S_N.txt
# AGC_AKT__AKT1
open(F,$ARGV[1])or die;
while(<F>){
  chomp;
  @fields = split("_",$_);
  $k=$fields[3];
  
  if($fields[3] =~ /\//){
    # dealing with proteins with two names in manning's file (eg. ZC1/HGK)
    my @t=split("/",$fields[3]);
    $k=$t[1];
  }
  $manning_list{$k}=join("_",@fields[0..2]);
}
close(F);

########
#open(PDBENT,"/aloy/data/dbs/pdbmirror/derived_data/index/entries.idx") or die; # provide PDB entries.idx file
#while(<PDBENT>){
  #@fields=split("\t",$_);
  #$pdb_org{lc($fields[0])}=$fields[4];
#}
#close(PDBENT);
#########


#foreach(sort keys %bestmods_list){
  #if(exists $manning_list{$_}){;}
  #else {print "$_\n";}
#}

## process best models.
open(OUT,">tmp.txt") or die;
foreach(keys %bestmods_list){
  
  ## if it has a PDB assigned
  if(defined $bestmods_list{$_}[1]){
  
    # setting the label 3DSTR or 3DHOM
    if($bestmods_list{$_}[6]==100 && $bestmods_list{$_}[7]==100){$label="3DSTR";}else{$label="3DHOM";}
    
    ## mapping PDBID->SourceOrg
    if(defined $bestmods_list{$_}[1]){
      my ($pdb,$chain) = split("_",$bestmods_list{$_}[1]);
      $sourceorg = $pdb_org{lc($pdb)};
    }else{$sourceorg = "missing_source_organism";}
    
    if(exists $manning_list{$_}){
      ## Group Family Subfamily
      print OUT "$manning_list{$_}\t$_\t";
    }else{
      ## Missing Group Family Subfamily
      print OUT "GroupFamSubFam\tmapping\tmissing\t$_\t";
      print "$_\t Group-Family-SubFam mapping missing, please map it manually\n";
    }
    ## PDB SI QC SC E-value Label PDBSourceOrganism
    print OUT "$bestmods_list{$_}[1]\t$bestmods_list{$_}[6]\t$bestmods_list{$_}[7]\t$bestmods_list{$_}[8]\t$bestmods_list{$_}[9]\t$label\t$sourceorg\n";
    
  }else{
    ## if it does not has a PDB assigned
    if(exists $manning_list{$_}){
      ## Group Family Subfamily
      print OUT "$manning_list{$_}\t$_\n";
    }else{
      ## Missing Group Family Subfamily
      print OUT "GroupFamSubFam\tmapping\tmissing\t$_\n";
      print "$_\t Group-Family-SubFam mapping missing, please map it manually\n";
    }
  }
}
close(OUT);

system("sort tmp.txt > output.txt");
unlink("tmp.txt");

