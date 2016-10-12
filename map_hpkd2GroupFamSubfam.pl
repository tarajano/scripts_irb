#!/usr/bin/env perl 
#
# 
#

use strict;
use warnings;

my @hpkdtomap;
my %manning_list;
my @fields;
my %pdb_org;
my $k; my $label; my $sourceorg;


############
## loading input file
# ABL1  252 1fpu  A 275 251 252 252 1 252 18  269 99.6  100.0 91.6  6e-150
# ABL1  252 1fpu  A 275 251 252 252 1 252 18  269 99.6  100.0 91.6  2e-124
open(F,$ARGV[0])or die;
@hpkdtomap=<F>;
chomp(@hpkdtomap);
close(F);
############


############
## loading Manning s file
## /home/malonso/phd/kinome/hpk/hpk_domains/ePKtree/manning_2002_TableS1_G_F_S_N.txt
open(F,"/home/malonso/phd/kinome/hpk/hpk_domains/ePKtree/manning_2002_TableS1_G_F_S_N.txt")or die;
while(<F>){
  chomp;
  @fields = split("\t",$_);

  if($fields[3] =~ /\//){
    # dealing with proteins with two names in manning's file (eg. ZC1/HGK)
    my @t=split("/",$fields[3]);
    $k=$t[1];
  }else{
    $k=$fields[3];
  }
  $manning_list{$k}=join("_",@fields[0..3]);
}
close(F);
############

############
open(OUT,">tmp.txt") or die;
foreach (@hpkdtomap){
  my @fields = split("\t",$_);
  my $hpkdname = $fields[0];
  #print "$hpkdname\n";
  if(exists $manning_list{$hpkdname}){
    ## Group Family Subfamily
    $fields[0]=$manning_list{$hpkdname};
    my $string = join("\t",@fields);
    print OUT "$string\n";
  }else{
    ### Missing Group Family Subfamily
    print OUT "GroupFamSubFam\tmapping\tmissing\t$_\t\n";
    my $string = join("\t",@fields);
    print OUT "$string\n";
    print "$_\t Group-Family-SubFam mapping missing, please map it manually\n";
  }
}
close(OUT);

system("sort tmp.txt > output.txt");
unlink("tmp.txt");
############
