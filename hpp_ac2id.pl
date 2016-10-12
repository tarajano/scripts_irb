#!/usr/bin/env perl
#
#
#
use strict;
use warnings;

my %ac2id=();

open(I,"/home/malonso/phd/kinome/hpp/139HPP_folder/139_ac2id.list")or die;
while(<I>){
  chomp;
  my ($ac,$id)=split("\t",$_);
  $ac2id{$ac}=$id;
}
close(I);

open(I,$ARGV[0]) or die; # file in which substitute UniprotAC by the UniprotID
while(<I>){
  chomp;
  if(/^(\w{6})_/){
    my $ac = $1;
    my $line = $_;
    $line =~ s/$ac/$ac2id{$ac}/;
    print "$line\n";
  }else{
    print "$_\n";
  }
}
close
