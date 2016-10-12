#!/usr/bin/env perl
#
# Jan. 2011 by MAlonso
#
# Generating RAPIDO's scripts files for Structural Superposition of HPKDs
#
# This script do several things:
# 1) Queries hpkd_db for identifying HPK families for which there is at least one member with an available R3DS (real 3D structure).
# 2) Generates the Families-pairs to be superposed among HPK Groups. (within-groups superpositions scripts are done by "heatmaps_flex-rmsd_families-in-groups.pl")
# 3) Generates the needed directories structures in which str.superpositions will be performed.
# 4) Generates RAPIDO scripts for superpositions in each famA vs famB among HPK groups.
# 5) Generates a file with the full paths of each RAPIDO input file. (this list will be used to create an ArrayJob)
# 
# After executing this script an ArrayJob must be created in order to run the Structural Superpositions with RAPIDO.
# 
# To be run from the folder "among-groups_Fam_vs_Fam/"
# Needs acces to DB hpkd_db
#
#

use DBI;
use strict;
use warnings;
use File::Find;

## Define the HPK Groups to be processed
my @hpk_groups= qw(AGC CAMK CK1 CMGC Other STE TK TKL Atypical);

my (@fams_g_3D,@fams_gg_3D,@fam1_realstrs,@fam2_realstrs);
my @families_comparison_pairs; ## array of arrays ((,), (,), (,))


my $ini_dir=`pwd`;
chomp($ini_dir);


##############################
## Iterating through HPK group comparison pairs
for (my $g=0; $g < $#hpk_groups; $g++){
  print "processing group $hpk_groups[$g]\n";
  
  my $gg;
  
  ## creating current GROUP directory and moving into it
  mkdir($hpk_groups[$g]) unless (-e $hpk_groups[$g]);
  my $change_dir=$ini_dir."/".$hpk_groups[$g]."/";
  chdir($change_dir) or die;
  
  ## Retrieving a list of FAMILIES in GROUP with at least one real 3D structure
  @fams_g_3D = fams_in_group_with_at_least_one_real_struct($hpk_groups[$g]);
  
  for($gg=$g+1;$gg <= $#hpk_groups; $gg++){
    print "\t$hpk_groups[$g]\t$hpk_groups[$gg]\n";
    
    ## Retrieving a list of FAMILIES in GROUP with at least one real 3D structure
    @fams_gg_3D = fams_in_group_with_at_least_one_real_struct($hpk_groups[$gg]);

    ## Generating pairs (pairwise) of families to be superposed
    @families_comparison_pairs = families_comparison_pairs_among_groups(\@fams_g_3D,\@fams_gg_3D);
    
    ## Fetching the names of real structures in the families to be superposed
    foreach (@families_comparison_pairs){
      my ($fam1, $fam2) = @{$_};
      ## Retrieving the real structures files in for fam1 & fam2
      my ($ref1, $ref2) = get_real_structures_in_fam_pairs_among_groups($fam1, $fam2);
      @fam1_realstrs = @{$ref1};
      @fam2_realstrs = @{$ref2};
      
      #####
      ### testing fetched structures 
      #print "\n\n=== $fam1, $fam2 ===\n";
      #print "$_\n" foreach(@fam1_realstrs);
      #print "\t$_\n" foreach(@fam2_realstrs); 
      #####
            
      ### Generating folders for each families_comparison_pairs
      my $fams_folder_name = mkdir_fam_pairs_folder_among_groups($hpk_groups[$g],$hpk_groups[$gg],$fam1,$fam2); 
      ### Generating RAPIDO scripts for each prot vs prot superposition in the current families pair
      generating_RAPIDO_script_files(\@fam1_realstrs,\@fam2_realstrs,$fams_folder_name);
    }
  }
  
  ## return to initial directory
  chdir($ini_dir) or die;
}

## generating file with the list/paths of RAPIDO input scripts
print "generating file RAPIDO_scripts.list\n";
generate_RAPIDO_input_scripts_list();
##############################


##############################
#### SUBROUTINES #############
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
## 1. Generating folders for each families_comparison_pairs
## Arguments: current GROUP name, ref to the array of families pairs
##
sub mkdir_fam_pairs_folder_among_groups{
  my $group1 = $_[0];
  my $group2 = $_[1];
  my $fam1 = $_[2];
  my $fam2 = $_[3];
  
  my $fam_folder_name = $group1."_".$fam1."_vs_".$group2."_".$fam2;
  mkdir($fam_folder_name) unless (-e $fam_folder_name);
  
  return $fam_folder_name;
}
##############################

##############################
## Generating lists of real structures in Fam1 and Fam2
## Arguments: families names of current family pair. array of array "@families_comparison_pairs"
## Returns: Two references to arrays containing the names of the PDB files of each family
## 
## Notes Regarding the query to the DB:
##  In Human, PK families' names are unique; thats why in this case is it possible to fetch the
##  right protein list by only searching for the family name (hpkd_family) and the need_to_model attributes.
## 
sub get_real_structures_in_fam_pairs_among_groups{
  my ($fam1, $fam2) = ($_[0],$_[1]);
  my (@fam1,@fam2);
  
  ######
  ## connecting DB
  my $conn = DBI->connect("dbi:Pg:dbname=hpkd_db;host=localhost;port=5433;user=malonso;password='manuel'");
  ## querying DB for fam1 real structures
  my $query = $conn->prepare("SELECT template_file FROM hpkd_templates_realseq WHERE hpkd_family = '$fam1' AND need_to_model='no'")or die $conn->errstr;
  $query->execute() or die $conn->errstr;
  ## fetching names of fam1 real structures
  while (my @row = $query->fetchrow_array()){
    push(@fam1,$row[0]);
  }
  ## querying DB for fam1 real structures
  $query = $conn->prepare("SELECT template_file FROM hpkd_templates_realseq WHERE hpkd_family = '$fam2' AND need_to_model='no'")or die $conn->errstr;
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
## Returs an array of arrays containing the pairs of families to be superposed ((,), (,), (,)).  G1_fams vs G2_fams
## Arguments: Refs to two arrays generated by the subroutine "&fams_in_group_with_at_least_one_real_struct()"
##
sub families_comparison_pairs_among_groups{
  my @g_fams = @{$_[0]};
  my @gg_fams = @{$_[1]};
  my @families_comparison_pairs;

  foreach my $g (sort {$a cmp $b} @g_fams){
    foreach my $gg (sort {$a cmp $b} @gg_fams){
      push(@families_comparison_pairs,[$g,$gg]);
    }
  }
  return @families_comparison_pairs;
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





