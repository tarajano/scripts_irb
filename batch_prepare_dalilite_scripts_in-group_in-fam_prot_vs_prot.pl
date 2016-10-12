#!/usr/bin/env perl
#
# created on: 18/Jan/2011 by M.Alonso
#
# Generating DaliLite's scripts files (&folders structures) for the Structural Superposition of all-vs-all R3DS inside each HPK family.
# 
#
#
#
#

use DBI;
use strict;
use warnings;
use File::Find;

## Define the HPK Groups to be processed
my @hpk_groups =  qw(AGC CAMK CK1 CMGC Other RGC STE TK TKL Atypical);
my (@families,@fam_realstrs);

## iterating trough the HPK groups 
foreach my $group (@hpk_groups){
  print "processing group $group\n";

  ## Retrieving a list of FAMILIES in GROUP with at least one real 3D structure
  @families = fams_in_group_with_at_least_one_real_struct($group);
  
  if($#families >= 0){
    ## create GROUP directory
    mkdir($group);

    ## Fetching the names of real structures in the families to be superposed
    foreach my $fam (@families){
      ### Retrieving the real structures files in for fam1
      @fam_realstrs = get_real_structures($group, $fam);
      
      ### Generating folders for each families_self_comparisons
      my $fams_folder = mkdir_fams_folders($group,$fam); 
      ### Generating DALI scripts for each prot vs prot superposition in the current family
      generating_DALI_script_files(\@fam_realstrs,$fams_folder);
    }  
  }
}

## generating file with the list/paths of DALI input scripts
print "generating file DALI_scripts.list\n";
generate_DALI_input_scripts_list();


##############################
#### SUBROUTINES #############
##############################

##############################
## Generating lists of real structures in Fam
## Arguments: current group, current family name
## Returns: array containing the names of the PDB files
## 
sub get_real_structures{
  my ($group, $fam) = ($_[0],$_[1]);
  my @fam;
  
  ######
  ## connecting DB
  my $conn = DBI->connect("dbi:Pg:dbname=hpkd_db;host=localhost;port=5433;user=malonso;password='manuel'");
  ## querying DB for fam real structures
  my $query = $conn->prepare("SELECT template_file FROM hpkd_templates_realseq WHERE hpkd_group='$group' AND hpkd_family = '$fam' AND need_to_model='no'")or die $conn->errstr;
  $query->execute() or die $conn->errstr;
  ## fetching names of fam real structures
  while (my @row = $query->fetchrow_array()){
    push(@fam,$row[0]);
  }
  ## disconnecting DB
  $conn->disconnect();
  ######
  return @fam;
}
##############################


##############################
## 1. Generating folders for each families_self_comparisons
## Arguments: current GROUP name, ref to the array of families pairs
##
sub mkdir_fams_folders{
  my $group = $_[0];
  my $fam = $_[1];
  my $fam_folder_name = $group."/".join("_vs_",($fam,$fam));
  mkdir($fam_folder_name) unless (-e $fam_folder_name);
  return $fam_folder_name;
}
##############################

##############################
## Returns a list of FAMILIES in GROUP that contains at least one real 3D structure
## Arguments: current HPK Group
sub fams_in_group_with_at_least_one_real_struct{
  my $group = $_[0];
  my @list;
  
  ######
  ## connecting DB
  my $conn = DBI->connect("dbi:Pg:dbname=hpkd_db;host=localhost;port=5433;user=malonso;password='manuel'");
  ## querying DB 
  my $query = $conn->prepare("SELECT distinct(hpkd_family) FROM hpkd_templates_realseq WHERE hpkd_group='$group' AND need_to_model='no'")or die $conn->errstr;
  $query->execute() or die $conn->errstr;
  ## fetching results
  while (my @row = $query->fetchrow_array()){
    push(@list,$row[0]);
  }
  ## disconnecting DB
  $conn->disconnect();
  ######
  return @list;
}
##############################

##############################
## Generating DALI script file for each Prot vs Prot comparison
sub generating_DALI_script_files{

  # provide PDB file names and corresponding fami self-comparison folder name
  my @fam = @{$_[0]};
  my $fam_folder = $_[1];
  my $path_to_structures = "/aloy/home/malonso/phd/phd/kinome/hpk/hpkdoms/hpkd_SI95QC95/strs/";
  my @tmp;
  my ($str1,$fam1,$hpk1,$pdb1,$chain1,$name1,$dirname1);
  my ($str2,$fam2,$hpk2,$pdb2,$chain2,$name2,$dirname2);
  
  ## Preparing data for generating DALI script files
  for(my $f=0 ; $f<=$#fam; $f++){
    $name1 = $fam[$f];
    $dirname1 = $name1;
    $dirname1 =~ s/\.pdb//;
    $str1 = $path_to_structures.$fam[$f];

    my @c_fam = @fam; ## a copy of @fam2
    for(my $ff = ($f+1) ; $ff<=$#c_fam; $ff++){
      $name2 = $fam[$ff];
      $dirname2 = $name2;
      $dirname2 =~ s/\.pdb//;
      $str2 = $path_to_structures.$fam[$ff];

      ## Creating the directory for each Fam1-protA vs Fam2-protX superposition
      my $dir_name = $fam_folder."/".$dirname1."_vs_".$dirname2."/";
      mkdir($dir_name);
      ## Copying PDB files folder
      system("cp $str1 $dir_name");
      system("cp $str2 $dir_name");
      
      ## Creating the name for each DALI script file
      my $DALI_script_name = $dirname1."_vs_".$dirname2.".dali";
      
      ## writing to DALI script file
      open(DALI_SCRIPT,">$dir_name$DALI_script_name") or die;
      print DALI_SCRIPT "/aloy/data/programs/DaliLite_3.3/DaliLite -pairwise $name1 $name2 > log";
      close(DALI_SCRIPT);
    }
  }
}
##############################

##############################
## Generating a file with the full paths of DALI input files.
## The generated file will be used to create an ArrayJob script for running DALI in the cluster
sub generate_DALI_input_scripts_list{
  my $current_dir = `pwd`;
  chomp($current_dir);
  
  open(INP_LIST,">DALI_scripts.list") or die;
  ###
  find(\&DALI_script_folder, $current_dir);
  sub DALI_script_folder{
    my $elemento = $_;
    if (-f $elemento && $elemento =~ /\.dali$/ ){
      #chdir($File::Find::dir);
      print INP_LIST "$File::Find::name\n";
    }
  }
  ###
  close(INP_LIST);
}
##############################

 







