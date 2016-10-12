#!/usr/bin/env perl
#
# ./scripts/report_hpkd_bestmodelsTables.pl hpkdoms516.bestresults_classif_v2 
#  
# Script for compiling a resume of the bestmodel file from scanpdb
#  
# The script parses the bestmodel file and creates a report of available 3D structures 
# by Group, Family, Subfamily and Protein.
# 
#Group-::: 3D strs available in the group/total proteins in group | diff PDBs among the available 3D strs / 3D strs available in the group
        #Family-::2/3 | 2/2 3D strs available in the family/total proteins in family | diff PDBs among the available 3D strs / 3D strs available in the family
        #Family-::1/7
                #Subfamily-:0/4
                #Subfamily-:1/2

#
# Note: For obtaining the complete classification of HPKs (class,fam,subfam,protname) as in the following example
# you might need to use hpk_mapp_name2famsubfam.pl giving the bestmodes file as input.)
#
# example input: (HPKDs classification muys be tab-delimited)
#AGC  AKT   AKT1  3cqu_A  1 259 7 265 99.6  100.0 81.2  3e-152  2.2 X-RAY DIFFRACTION
#AGC  AKT   AKT2  3e88_A  1 258 7 264 99.6  100.0 80.4  7e-152  2.5 X-RAY DIFFRACTION
#AGC  AKT   AKT3
#AGC  DMPK    CRIK
#AGC  DMPK  GEK DMPK1
#AGC  DMPK  GEK DMPK2
#
# example output: 
#
#AGC-:::10/63 | 10/10
        #AKT-::2/3 | 2/2
        #DMPK-::1/7
                #GEK-:0/4
                #ROCK-:1/2
        #GRK-::2/7 | 2/2
                #BARK-:1/2
                #GRK-:1/5
        #MAST-::0/5
        #NDR-::0/4
        #PKA-::1/5
        #PKB-::1/1
        #PKC-::3/9 | 3/3
#
#

use strict;
use warnings;
use List::MoreUtils qw(uniq); # @a = uniq(@a) , for eliminating duplicated entries in an array.

###
# AGC     AKT       X      AKT1    3cqu_A  1 .....
open(F,$ARGV[0]) or die; # hpk/SI90QC99/hpkdoms516.bestmodels_classif_v2 
my @bestmodels=<F>;
chomp(@bestmodels);
close(F);

my @fields;
my %hpkd_3D_info;

foreach (@bestmodels){
  @fields = split("\t",$_);
  if(defined $fields[4]){
    # If there's a 3D str for the current hpk domain assign value 1 to the current protein
    # $fields[0] : Group
    # $fields[1] : Fam 
    # $fields[2] : Subfam
    # $fields[3] : Prot
    $hpkd_3D_info{$fields[0]}{$fields[1]}{$fields[2]}{$fields[3]}=$fields[4];
  }else{
    $hpkd_3D_info{$fields[0]}{$fields[1]}{$fields[2]}{$fields[3]}="";
  }
}
##

open(GROUP3D, ">Groups3Dinfo.report") or die;
#print GROUP3D "group\tfams_in_grp3D\t\tfams_in_grp\tsubfams_in_grp3D\t\tsubfams_in_grp\tprots_in_grp3D\t\tprots_in_grp\tpdbs_in_grp\tprots_in_grp3D\n";
## group  fams_in_grp3D fams_in_grpNo3D fams_in_grp subfams_in_grp3D  subfams_in_grpNo3D  subfams_in_grp  prots_in_grp3D  prots_in_grpNo3D  prots_in_grp
print GROUP3D "group\tfams_in_grp3D\tfams_in_grpNo3D\tfams_in_grp\tsubfams_in_grp3D\tsubfams_in_grpNo3D\tsubfams_in_grp\tprots_in_grp3D\tprots_in_grpNo3D\tprots_in_grp\tpdbs_in_grp\tprots_in_grp3D\n";


#group
foreach my $group (sort{$a cmp $b} keys %hpkd_3D_info){
  my %grpinfo; my @faminfo; my @subfaminfo;
  my @pdbs_in_grp;
  my $prots_in_grp=0;   my $prots_in_grp3D=0;
  my $prots_in_fam=0;   my $prots_in_fam3D=0;
  my $prots_in_subfam=0;my $prots_in_subfam3D=0;
  
  # subfamilies in each group
  my @subfams_in_grp; my $subfams_in_grp=0; my $subfams_in_grp3D=0;

  # families in each group
  my @fams_in_grp; my $fams_in_grp; my $fams_in_grp3D=0;
  @fams_in_grp = keys %{$hpkd_3D_info{$group}};
  $fams_in_grp = @fams_in_grp;
  
  #fam
  foreach my $fam (sort{$a cmp $b} keys %{$hpkd_3D_info{$group}}){
    @faminfo="";
    my @pdbs_in_fam;
    $prots_in_fam=0;
    $prots_in_fam3D=0;
    my $subfamprot3Dflag; # for counting the number of subfams with 3d str
    
    #subfam
    foreach my $subfam (sort{$a cmp $b} keys %{$hpkd_3D_info{$group}{$fam}}){
      @subfaminfo="";
      $prots_in_subfam3D=0; $subfamprot3Dflag=0;
      
      $prots_in_subfam = keys %{$hpkd_3D_info{$group}{$fam}{$subfam}};
      $prots_in_fam = $prots_in_subfam+$prots_in_fam;
      
      #prot
      foreach my $prot (keys %{$hpkd_3D_info{$group}{$fam}{$subfam}}){
        
        if($hpkd_3D_info{$group}{$fam}{$subfam}{$prot} ne ""){
          $prots_in_subfam3D++;
          #storing pdbs in subfamily
          push(@pdbs_in_fam,$hpkd_3D_info{$group}{$fam}{$subfam}{$prot});
          ##
          if($subfam ne "" && $subfamprot3Dflag==0){$subfamprot3Dflag++; $subfams_in_grp3D++;}
        }
      }#prot
      $prots_in_fam3D = $prots_in_subfam3D + $prots_in_fam3D;
      
      if ($subfam ne ""){
        $prots_in_subfam = keys %{$hpkd_3D_info{$group}{$fam}{$subfam}};
        push (@subfaminfo,"\t\t$subfam-:$prots_in_subfam3D/$prots_in_subfam\n");
      }
      ## storing family-subfamily 3D info
      push(@faminfo,@subfaminfo);
    }#subfam
    
    # storing subfamilies in the group
    push(@subfams_in_grp,keys %{$hpkd_3D_info{$group}{$fam}});
    # counting number of subfamilies in the group with at least one 3D str
    # $subfams_in_grp3D++ if($prots_in_subfam3D>0);
    #$subfams_in_grp3D = ;

    ## counting uniq pdbs in the family
    my $pdbs_in_fam = uniq(@pdbs_in_fam);
    
    if($prots_in_fam3D>1){
      # if there are 2 or more pdbs in the family then add the data to the string
      $grpinfo{"$fam-::$prots_in_fam3D/$prots_in_fam | $pdbs_in_fam/$prots_in_fam3D"}=[@faminfo];
    }else{
      $grpinfo{"$fam-::$prots_in_fam3D/$prots_in_fam"}=[@faminfo];
    }
    
    $prots_in_grp = $prots_in_grp + $prots_in_fam;
    $prots_in_grp3D = $prots_in_grp3D + $prots_in_fam3D;
    push(@pdbs_in_grp,@pdbs_in_fam);
    
    # counting number of families in the group with at least one 3D str
    $fams_in_grp3D++ if($prots_in_fam3D>0);
  }#fam
  
  # saving the number of subfamilies in each group
  @subfams_in_grp=uniq(@subfams_in_grp);
  foreach(@subfams_in_grp){unless($_ eq ""){$subfams_in_grp++;}}
  
  ## counting uniq pdbs in the group
  my $pdbs_in_grp = uniq(@pdbs_in_grp);
  
  ## printing out str info
  #print GROUP3D "$group\t$fams_in_grp3D\t".($fams_in_grp - $fams_in_grp3D)."\t$subfams_in_grp3D\t".($subfams_in_grp-$subfams_in_grp3D)."\t$prots_in_grp3D\t".($prots_in_grp-$prots_in_grp3D)."\t$pdbs_in_grp/$prots_in_grp3D\n";
  
  ## group  fams_in_grp3D fams_in_grpNo3D fams_in_grp subfams_in_grp3D  subfams_in_grpNo3D  subfams_in_grp  prots_in_grp3D  prots_in_grpNo3D  prots_in_grp
  print GROUP3D "$group\t$fams_in_grp3D\t".($fams_in_grp-$fams_in_grp3D)."\t$fams_in_grp\t$subfams_in_grp3D\t".($subfams_in_grp-$subfams_in_grp3D)."\t$subfams_in_grp\t$prots_in_grp3D\t".($prots_in_grp-$prots_in_grp3D)."\t$prots_in_grp\t$pdbs_in_grp\t$prots_in_grp3D\n";
  ##
  #print "$group-:::$prots_in_grp3D/$prots_in_grp | $pdbs_in_grp/$prots_in_grp3D\n";
  print "$group-:::$prots_in_grp3D/$prots_in_grp\n";
  foreach my $k (sort{$a cmp $b} keys %grpinfo){
    print "\t$k\n";
    print "$_" foreach (@{$grpinfo{$k}});
  }

  print "\n";
}

close(GROUP3D);


