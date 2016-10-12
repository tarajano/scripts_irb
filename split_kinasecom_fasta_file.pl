#!/usr/bin/perl -w
# 
# takes a kinase.com fasta file as input
# 
# input file example:  
#>TTBK2_Hsap (CK1/TTBK)
#MSGGGEQLDILSVGI


my %PKcom_seq;
# loading hash PKcom=>seq from file Human_kinase_domain.fasta
open(F,$ARGV[0]) or die; # provide file Human_kinase_domain.fasta
my @infile =<F>;
chomp(@infile);
my $key;
foreach (@infile){
  if(/^>(.*)\s/){
    $key=$1;
    #print "$key\n";
  }elsif(/^[A-Z]/){
    $PKcom_seq{$key}=$_;
  }else{;}
}
close(F);

foreach (keys %PKcom_seq){
  my $outfile=$_."_hpkprot.fasta";
  open(O,">$outfile") or die;
  print O ">$_\n$PKcom_seq{$_}\n";
  close(O);
  #print "$_\n";
}
