#!/usr/bin/env perl
#
# Dic.2010. by MAlonso
#
# Generating RAPIDO's scripts files for Structural Superposition of HPKDs
#
# This script do several things:
# 1) Queries hpkd_db for identifying HPK families for which there is at least one member with an available R3DS (real 3D structure).
# 2) Generates the Families-pairs to be superposed inside each HPK Group.
# 3) Generates the needed directories structures in which str.superpositions will be performed.
# 4) Generates RAPIDO scripts for prot vs prot superpositions in each famA vs famB into each HPK group.
# 5) Generates a file with the full paths of each RAPIDO input file. (this list will be used to create an ArrayJob)
# 
# After executing this script an ArrayJob must be created in order to run the Structural Superpositions with RAPIDO.
#
#

use DBI;
use strict;
use warnings;
use File::Find;

## Define the HPK Groups to be processed
#my @hpk_groups =  qw(AGC CAMK CK1 CMGC Other RGC STE TK TKL Atypical);
my @hpk_groups =  qw(Atypical);
my (@families,@fam1_realstrs,@fam2_realstrs);
my @families_comparison_pairs; ## array of arrays ((,), (,), (,))
my %strs_flex_rmsd=();


## iterating trough the HPK groups 
foreach my $group (@hpk_groups){
  print "processing group $group\n";

  ## Retrieving a list of FAMILIES in GROUP with at least one real 3D structure
  @families = fams_in_group_with_at_least_one_real_struct($group);
  
  if($#families > 0){
    ## create GROUP directory
    mkdir($group);
    ## Generating pairs of families to be superposed
    @families_comparison_pairs = families_comparison_pairs(@families);

    ## Fetching the names of real structures in the families to be superposed
    foreach (@families_comparison_pairs){
      my ($fam1, $fam2) = @{$_};
      ## Retrieving the real structures files in for fam1 & fam2
      my ($ref1, $ref2) = get_real_structures_in_fam_pair($group, $fam1, $fam2);
      @fam1_realstrs = @{$ref1};
      @fam2_realstrs = @{$ref2};
      ## Generating folders for each families_comparison_pairs
      my $fams_folder = mkdir_fam_pairs_folder($group,$fam1,$fam2); 
      ## Generating RAPIDO scripts for each prot vs prot superposition in the current families pair
      #generating_RAPIDO_script_files(\@fam1_realstrs,\@fam2_realstrs,$fams_folder);
    }  
  }elsif($#families == 0){
    print "Group $group have only one (or non) family with real 3D structures. No Fam vs. Fam comparison pairs can be generated\n";
    @families_comparison_pairs = "";
  }
}

## generating file with the list/paths of RAPIDO input scripts
print "generating file RAPIDO_scripts.list\n";
#generate_RAPIDO_input_scripts_list();


##############################
#### SUBROUTINES #############
##############################

##############################
## Generating lists of real structures in Fam1 and Fam2
## Arguments: current group, families names of current family pair
## Returns: Two references to arrays containing the names of the PDB files
## 
sub get_real_structures_in_fam_pair{
  my ($group, $fam1, $fam2) = ($_[0],$_[1],$_[2]);
  my (@fam1,@fam2);
  
  ######
  ## connecting DB
  my $conn = DBI->connect("dbi:Pg:dbname=hpkd_db;host=localhost;port=5433;user=malonso;password='manuel'");
  ## querying DB for fam1 real structures
  my $query = $conn->prepare("SELECT template_file FROM hpkd_templates_realseq WHERE hpkd_group='$group' AND hpkd_family = '$fam1' AND need_to_model='no'")or die $conn->errstr;
  $query->execute() or die $conn->errstr;
  ## fetching names of fam1 real structures
  while (my @row = $query->fetchrow_array()){
    push(@fam1,$row[0]);
  }
  ## querying DB for fam1 real structures
  $query = $conn->prepare("SELECT template_file FROM hpkd_templates_realseq WHERE hpkd_group='$group' AND hpkd_family = '$fam2' AND need_to_model='no'")or die $conn->errstr;
  $query->execute() or die $conn->errstr;
  ## fetching names of fam2 real structures
  while (my @row = $query->fetchrow_array()){
    push(@fam2,$row[0]);
  }
  ## disconnecting DB
  $conn->disconnect();
  ######
  return (\@fam1,\@fam2);
}
##############################


##############################
## 1. Generating folders for each families_comparison_pairs
## Arguments: current GROUP name, ref to the array of families pairs
##
sub mkdir_fam_pairs_folder{
  my $group = $_[0];
  my $fam1 = $_[1];
  my $fam2 = $_[2];
  my $fam_folder_name = $group."/".join("_vs_",($fam1,$fam2));
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
## Returs an array of arrays containing the pairs of families to be superposed ((,), (,), (,))
## Arguments: array generated by the subroutine "&fams_in_group_with_at_least_one_real_struct()"
##
sub families_comparison_pairs{
 my @list = @_;
 my @families_comparison_pairs;
 
 for(my $i=0; $i<$#list; $i++){
    for(my $ii = $i+1; $ii<=$#list; $ii++){
      push(@families_comparison_pairs,[$list[$i],$list[$ii]]);
    }
  }
  #print "@{$_}\n" foreach(@families_comparison_pairs);
  return @families_comparison_pairs;
}
##############################

##############################
## Generating RAPIDO script file for each Prot vs Prot comparison
sub generating_RAPIDO_script_files{

  # provide FAM-1 & FAM-2 names and corresponding fam1_vs_fam2 folder name
  my @fam1 = @{$_[0]};
  my @fam2 = @{$_[1]};
  my $fam_folder = $_[2];
  my $path_to_structures = "/aloy/home/malonso/phd/phd/kinome/hpk/hpkdoms/hpkd_SI95QC95/strs/";
  my @tmp;
  my ($str1,$fam1,$hpk1,$pdb1,$chain1,$name1);
  my ($str2,$fam2,$hpk2,$pdb2,$chain2,$name2);
  
  ## loading RAPIDO template file
  open(RAPIDO_TEMPLATE,"/home/malonso/phd/kinome/scripts/RAPIDO_SCRIPT.template") or die;
  my @RAPIDO_TEMPLATE = <RAPIDO_TEMPLATE>;
  close(RAPIDO_TEMPLATE);
  
  ## Preparing data for generating RAPIDO script files
  foreach my $str1 (@fam1){
    $name1 = $str1;
    $name1 =~ s/\.pdb//;
    $str1 = $path_to_structures.$str1;
    @tmp=split("_",$name1);
    $chain1 = chop($tmp[4]);
    $pdb1 = $tmp[4];

    my @c_fam2 = @fam2; ## a copy of @fam2
    foreach my $str2 (@c_fam2){
      $name2 = $str2;
      $name2 =~ s/\.pdb//;
      $str2 = $path_to_structures.$str2;
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

