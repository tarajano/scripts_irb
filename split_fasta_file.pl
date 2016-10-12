#!/usr/bin/perl -w
# takes a fasta file as input

### Define the output directory and create it if does not exists aready
my $outdir = "fastas/";
mkdir($outdir) unless(-d $outdir);

### Define the input file
my $outfile;
open(F,$ARGV[0]) or die;

while(<F>){
  if($_ =~ /^>\w{2}\|(\w+)/){
  ##if($_ =~ /^>(\S+)/){
  $outfile=$outdir.$1.".fasta";
    close(T) if(defined T);
    open(T,">$outfile") or die;
    print "$1\n";
    print T ">$1\n";
  }elsif(/^[A-Z]/){
    print T "$_";
  }

}
close (F);
