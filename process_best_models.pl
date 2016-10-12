#!/usr/bin/env perl
#
#
#
use strict;
use warnings;

my @fields;
my @bestmodels;
my $label;
my @g_fam_sub_prot;

## best models
## TK_CTKA__CTKA1_Mbre  1jpa_A  1 268 35  294 39.6  100 83.3  1.00E-049 1.91  X-RAY DIFFRACTION

open(F,$ARGV[0])or die; # provide the file best_models
@bestmodels=<F>;
chomp(@bestmodels);
close(F);

foreach my $mods (@bestmodels){
  @fields=split("\t",$mods);

  if(defined $fields[1]){
    
    if($fields[6]==100 && $fields[7]==100){$label="3DSTR";}
    else{$label="3DHOM";}
    
    ## group family subfamily protein
    @g_fam_sub_prot=split("_",$fields[0]);
    print "$_\t" foreach(@g_fam_sub_prot);
    ## 3DSTR || 3DHOM
    print "$label";
    ## PDB SI QC SC E-value
    print "\t$fields[1]\t$fields[6]\t$fields[7]\t$fields[8]\t$fields[9]\n";
  }else{
    ## group family subfamily protein
    @g_fam_sub_prot=split("_",$fields[0]);
    print "$_\t" foreach(@g_fam_sub_prot);
    print "\n";
  }
  

  
}
