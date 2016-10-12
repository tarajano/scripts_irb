#!/usr/bin/perl -w
# 
# takes a kinase.com fasta file as input
# 
# Input file example:  
# >TTBK2_Hsap (CK1/TTBK)
# MSGGGEQLDILSVGI
# 
# >proteinname_Hsap (PKGroup/PKfamiliy(/PKSubFamily)) 
# note that PKSubFamily may be present or not 
#  
# The Tree and Alignment files provided at http://kinase.com/human/kinome/phylogeny.html
# identify each protein as: 
# GROUP_FAMILY_SUBFAMILY_PROTEINNAME
#
# I will use the nomenclature: GROUP_FAMILY_SUBFAMILY_PROTEINNAME
# for naming each fasta file
#


my %PKcom_seq;
# loading hash PKcom=>seq from file Human_kinase_domain.fasta
open(F,$ARGV[0]) or die; # provide file Human_kinase_domain.fasta
my @infile =<F>;
chomp(@infile);
my $key;
foreach (@infile){
  if(/^>/){
    my ($group,$family,$subfamily,$proteinname)="";
    /^>
    (\S+) # proteinname.
    \s+\(
    (\w+) # group
    \/
    (\w+) # family
    \)?\/?
    (\w+) # subfamily
    ?\)?
    /x;
    $proteinname=$1; $group=$2; $family=$3;
    if(defined $4){$subfamily=$4;}else{$subfamily="";}
    $key=$group."_".$family."_".$subfamily."_".$proteinname;
    #print "$key\n";
  }elsif(/^[A-Za-z]/){
    $PKcom_seq{$key}=$_;
  }else{;}
}
close(F);

foreach (keys %PKcom_seq){
  my $outfile=$_.".fasta";
  open(O,">fastas/$outfile") or die;
  print O ">$_\n$PKcom_seq{$_}\n";
  close(O);
  #print "$_\n";
}
