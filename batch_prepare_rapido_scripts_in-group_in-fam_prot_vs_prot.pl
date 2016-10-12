#!/usr/bin/env perl
#
# created on: 07/Jan/2011 by M.Alonso
#
# Generating RAPIDO's scripts files (&folders structures) for the Structural Superposition of all-vs-all R3DS inside each HPK family.
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
      ### Generating RAPIDO scripts for each prot vs prot superposition in the current family
      generating_RAPIDO_script_files(\@fam_realstrs,$fams_folder);
    }  
  }
}

## generating file with the list/paths of RAPIDO input scripts
print "generating file RAPIDO_scripts.list\n";
generate_RAPIDO_input_scripts_list();


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
## Generating RAPIDO script file for each Prot vs Prot comparison
sub generating_RAPIDO_script_files{

  # provide PDB file names and corresponding fami self-comparison folder name
  my @fam = @{$_[0]};
  my $fam_folder = $_[1];
  my $path_to_structures = "/aloy/home/malonso/phd/phd/kinome/hpk/hpkdoms/hpkd_SI95QC95/strs/";
  my @tmp;
  my ($str1,$fam1,$hpk1,$pdb1,$chain1,$name1);
  my ($str2,$fam2,$hpk2,$pdb2,$chain2,$name2);
  
  ## loading RAPIDO template file
  open(RAPIDO_TEMPLATE,"/home/malonso/phd/kinome/scripts/RAPIDO_SCRIPT.template") or die;
  my @RAPIDO_TEMPLATE = <RAPIDO_TEMPLATE>;
  close(RAPIDO_TEMPLATE);
  
  ## Preparing data for generating RAPIDO script files
  for(my $f=0 ; $f<=$#fam; $f++){
    $name1 = $fam[$f];
    $name1 =~ s/\.pdb//;
    $str1 = $path_to_structures.$fam[$f];
    @tmp=split("_",$name1);
    $chain1 = chop($tmp[4]);
    $pdb1 = $tmp[4];

    my @c_fam = @fam; ## a copy of @fam2
    for(my $ff = ($f+1) ; $ff<=$#c_fam; $ff++){
      $name2 = $fam[$ff];
      $name2 =~ s/\.pdb//;
      $str2 = $path_to_structures.$fam[$ff];
      @tmp=split("_",$name2);
      $chain2 = chop($tmp[4]);
      $pdb2 = $tmp[4];
      
      ## Creating the directory for each Fam1-protA vs Fam2-protX superposition
      my $dir_name = $fam_folder."/".$name1."_vs_".$name2."/";
      mkdir($dir_name);
      
      ## Creating the name for each RAPIDO script file
      my $rapido_script_name = $name1."_vs_".$name2.".inp";
      
      ## writing to RAPIDO script file
      open(RAPIDO_SCRIPT,">$dir_name$rapido_script_name") or die;
      my @template_copy = @RAPIDO_TEMPLATE; # a copy of the template file
      foreach my $line (@template_copy){
        if($line =~ /RAPIDO_SCRIPT/){$line =~ s/RAPIDO_SCRIPT/$rapido_script_name/;}
        elsif($line =~ /PATH_STR1/){$line =~ s/PATH_STR1/$str1/; $line =~ s/PDB1/$pdb1/;}
        elsif($line =~ /CHAIN1/){$line =~ s/CHAIN1/$chain1/;}
        elsif($line =~ /PATH_STR2/){$line =~ s/PATH_STR2/$str2/; $line =~ s/PDB2/$pdb2/;}
        elsif($line =~ /CHAIN2/){$line =~ s/CHAIN2/$chain2/;}
        print RAPIDO_SCRIPT "$line";
      }
      close(RAPIDO_SCRIPT);
    }
  }
}
##############################

##############################
## Generating a file with the full paths of RAPIDO input files.
## The generated file will be used to create an ArrayJob script for running RAPIDO in the cluster
sub generate_RAPIDO_input_scripts_list{
  my $current_dir = `pwd`;
  chomp($current_dir);
  
  open(INP_LIST,">RAPIDO_scripts.list") or die;
  ###
  find(\&rapido_script_folder, $current_dir);
  sub rapido_script_folder{
    my $elemento = $_;
    if (-f $elemento && $elemento =~ /\.inp$/ ){
      #chdir($File::Find::dir);
      print INP_LIST "$File::Find::name\n";
    }
  }
  ###
  close(INP_LIST);
}
##############################

 







