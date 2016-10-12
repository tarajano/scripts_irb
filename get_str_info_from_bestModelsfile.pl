#!/usr/bin/env perl 
#
#  ~/phd/kinome/scripts/get_str_info_from_bestModelsfile.pl mouse_merged.out.best_models_v3 
# 
use strict;
use warnings;

my @bestmodsfile;
my @fields;
my %pkgroup;

open(F,$ARGV[0]) or die; # best_models file
@bestmodsfile=<F>; 
chomp(@bestmodsfile);

foreach(@bestmodsfile){
  @fields = split("\t",$_);
  $pkgroup{$fields[0]}=1;
}

foreach my $pkg (sort keys %pkgroup){
  my %fams; my %subfams; my %uniqhomologPDBs; my %uniqstrPDBs;
  my ($prots,$fams,$subfams)=0;
  my $str=0; my $hom=0; my $non=0;
  
  foreach my $line (@bestmodsfile){
    @fields = split("\t",$line);
    if($fields[0] eq $pkg){
      $prots++;
      $fams{$fields[1]}=1 if($fields[1] ne "");     # families
      $subfams{$fields[2]}=1 if($fields[2] ne "");  # subfamilies
        
      if(defined $fields[4]){
        if($fields[4] eq "3DSTR"){
          $str++;
          $uniqstrPDBs{$fields[5]}=1;
        }elsif($fields[4] eq "3DHOM"){
          $hom++;
          $uniqhomologPDBs{$fields[5]}=1;
        }elsif($fields[4] eq ""){
          $non++;
        }
      }else{
        $non++;
      }
      
    }
  }
  my $tmp=0;
  print "\nGroup $pkg\n";
  $fams=keys %fams; $subfams=keys %subfams;
  print "Families: $fams\nSub-Families: $subfams\nProteins: $prots\n";
  print "Proteins with 3D structure for the PK domain: $str\n";
  print "Proteins with 3D homolog for the PK domain: $hom\n";
  $tmp=keys %uniqhomologPDBs;
  print "\tUnique 3D homolog for the PK domain: $tmp/$hom\n";
  my %tmp =(%uniqhomologPDBs,%uniqstrPDBs);
  $tmp=0;
  $tmp = keys %tmp;
  print "Unique PDBs: $tmp\n";
  print "Proteins with no 3D information for the PK domain: $non\n";
  
  print "\nFamilies with at least one full 3DSTR: \nFamilies with only 3DHOM: (%)\nFamilies without any 3D info: \n";
  print "Sub-Families with at least one full 3DSTR: \nSub-Families with only 3DHOM: (%)\nSub-Families without any 3D info: \n";
  
  ##print "\tprots: $prots, fams: $fams, subfams: $subfams\n";
  ##print "\tAvailability of 3D info\n";
  ##print "\t\tstr: $str, hom: $hom, non: $non \n";
  ##print "\t\tunique 3D homolog for the PK domain: $tmp/$hom\n";
}





