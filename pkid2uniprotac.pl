#!/usr/bin/perl -w
# 
# Script to map kinome.com IDs to UniprotAC for the human PK.
# The map is done based on sequence comparison and only sequences with 100% identity are
# considered as "mapped" UniProtAC->KinomeID.
#

my %AC_seq;
my %PKcom_seq;


# loading hash AC=>seq from several fasta files
# provide the fasta files of canonical human PK from Uniprot recovered as a result of the search in uniprot : 
# ((ec:2.7.10.- OR ec:2.7.11.- OR ec:2.7.12.- OR ec:2.7.13. OR ec:2.7.99.) ) AND organism:"Human [9606]"

@files=<./557/*.fasta>;
foreach (@files){
  /(\w{6})\.fas/; # fetching AC from file name
  my $seq="";
  my $fileAC = $1;
  open(F,$_) or die;
  while(<F>){
    chomp;
    $seq=$seq.$_ if(/^[A-Z]/);
  }
  close(F);
  $AC_seq{$fileAC}=$seq;
}

# loading hash PKcom=>seq from file Human_kinase_protein.fasta Kinase.com
open(F,$ARGV[0]) or die; # provide file Human_kinase_protein.fasta 
my @infile =<F>;
chomp(@infile);
my $key;
foreach (@infile){
  if(/^>(.*)/){
    $key=$1;
  }elsif(/^[A-Z]/){
    $PKcom_seq{$key}=$_;
  }else{;}
}
close(F);


foreach my $AC (keys %AC_seq){
  foreach my $PK (keys %PKcom_seq){
    print "$AC -> $PK\n" if($AC_seq{$AC} eq $PKcom_seq{$PK});
  } 
}

#print "$_: $AC_seq{$_}\n" foreach (keys %AC_seq)
#print "$_: $PKcom_seq{$_}\n" foreach (keys %PKcom_seq)
