#!/usr/bin/env perl
#
# Jun 2010
#
# script for mapping the hpk domains with 3D structures or homologs in 
# the PDB onto the .dnd tree file generated by multiple alignment of domains
# sequences.
#
# usage:
# ./script.pl hpk_domains_best_models hpk_domains.dnd (.ph)
#
# 
# BUGS:
#
# The output file must be corrected given that the left-most Perl's substitution scheme 
# inserts the $label before proteinname when both proteinname and subfamilyname are the same
#

use strict;
use warnings;

open(F, $ARGV[0]) or die; # provide hpkdomain best 3D models file 
my @bestmodels=<F>;
chomp(@bestmodels);
close(F);

open(F, $ARGV[1]) or die; # provide ePK.ph file
my @tree=<F>;
chomp(@tree);
close(F);

my ($treeline,$hpkd,$label,$dualdomname);
my (@fields,@domtreefields);

################ use with my dnd file 
#foreach $treeline (@tree){
  
  #if($treeline =~ /(^\w.+)\:/){
    ### TK_JakB__Domain2_JAK3
    ### TK_TK-Unique__SuRTK106
    ### Other_NKF5__SgK307
    #@domtreefields = split("_",$1);
    
    #foreach $hpkd (@bestmodels){
      ### NEK2      2w5a_A  1       264     8       271     100     100     94.6    2.00E-156       1.55    X-RAY
      #@fields=split("\t",$hpkd);
      #if($fields[0] eq $domtreefields[3]){
        #if($fields[6]==100 && $fields[7]==100){
          #$label = $fields[0]."_3DSTR";
          #$treeline =~ s/$domtreefields[3]/$label/;
        #}else{
          #$label = $fields[0]."_3DHOM";
          #$treeline =~ s/$domtreefields[3]/$label/;
        #}
      #}
    #}
  #}
  
#print "$treeline\n";
#}
################ 

################ use with ePK.ph file
foreach $treeline (@tree){
  if($treeline =~ /(^\w.+)\:/){
    ## TKL_STKR_Type2_TGFbR2:0.27069
    @domtreefields = split("_",$1);
    
    foreach my $hpkd (@bestmodels){
      ## NEK2      2w5a_A  1       264     8       271     100     100     94.6    2.00E-156       1.55    X-RAY
      @fields=split("\t",$hpkd);
      
      ## if the hpk is single domain
      if($fields[0] eq $domtreefields[3]){
        if($fields[6]==100 && $fields[7]==100){
          $label = $fields[0]."_3DSTR_".$fields[1];
          $treeline =~ s/$domtreefields[3]/$label/;
        }else{
          $label = $fields[0]."_3DHOM_".$fields[1];
          $treeline =~ s/$domtreefields[3]/$label/;
        }
        
      ## elsif the hpk domain is dual domain
      }elsif($domtreefields[3] eq "Domain2"){
        if($fields[0] =~ /(^\w+)\~b/){ # get rid of ~b suffix of dualdomain for comparing domains' names
          $dualdomname=$1;
        }else{$dualdomname="NOTHING";}
        
        if($dualdomname eq $domtreefields[4]){ # now comparing dualdomain names in .ph file (Domain2) vs. dualdomain names in best models file (~b suffix)
          
          if($fields[6]==100 && $fields[7]==100){
            $label = $fields[0]."_3DSTR_".$fields[1];
            $treeline =~ s/$domtreefields[4]/$label/;
          }else{
            $label = $fields[0]."_3DHOM_".$fields[1];
            $treeline =~ s/$domtreefields[4]/$label/;
          }
        }
      }
    }
  }
print "$treeline\n";
}
################ 









