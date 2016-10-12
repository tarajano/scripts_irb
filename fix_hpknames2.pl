#!/usr/bin/perl -w
# fixing missing subfamily names in hpkp fasta file

my %hpks;
my (@fields,@hpkname); 
my $newhpkname;

open(F,$ARGV[0]) or die;
while(<F>){
  chomp();
  ## AGC_Akt_AKT1	01261	NP_005154.2
  @fields = split('\t+',$_);
  ## AGC_Akt_AKT1
  @hpkmane = split("_",$fields[0]);
    if($#hpkmane < 3){
      $newhpkname = join("_",$hpkmane[0],$hpkmane[1],"",$hpkmane[2]);
      printf("%s\n",join("\t",$newhpkname,$fields[1],$fields[2]));
    }else{
      print "$_\n" ;
    }
}
close(F);
