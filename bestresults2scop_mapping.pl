#!/usr/bin/env perl
#
#
#
use strict;
use warnings;

my %scop;

#######
## Best results file
open(F,$ARGV[0]) or die; # best results file from blast vs scop
my @bestresults = <F>;
chomp(@bestresults);
close(F);
#######

#######
## loading Scop classif file 
open(F,"/aloy/home/malonso/SCOP175/dir.cla.scop.txt_1.75") or die; # full path to scop classif file
while (<F>){
  chomp;
  if ($_ !~ /^#/ ){
    my @fields=split("\t",$_);
    $scop{$fields[0]}=[$fields[3],$fields[4]]; # storing {d1z5lb1}=[d.159.1.3,145523]
  }
}
close(F);
#######


#######
## adding scop classif to the bestresults file
my $headerline=0;
my @bestresults_scop;
my @tmp;
foreach (@bestresults){
  
  if($headerline>0){ # avoiding header line
    my @fields=split("\t",$_);
    if(defined $fields[1]){ # if there is a homolog in scop
      my $scop = join("\t",@{$scop{$fields[1]}});
      my $line =join("\t",@fields[2..$#fields]);
      push(@bestresults_scop,"$fields[0]\t$fields[1]\t$scop\t$line");
    }else{
      push(@bestresults_scop,$_);
    }
  }else{$headerline++;}
}

open(O,">blast.bestresults.scop") or die;
print O "QueryAC SubjectAC scopclassif scop_sunid Score E-value %_SeqID ConservRes Query_start Query_end %_QueryCov Subj_start Subj_end %_SubjCov HSP-QueryLength HSP-SubjectLength HSP-TotalLength\n";
print O "$_\n" foreach(@bestresults_scop);
#######



