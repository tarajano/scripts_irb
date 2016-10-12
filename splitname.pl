#!/usr/bin/env perl
#
# created on: 21/Feb/2011 by M.Alonso
#
use strict;
use warnings;

my @fields;
my @name;

open(F,$ARGV[0]) or die;
while(<F>){
  chomp();
	@fields = split('\t',$_);
	@name= split("_",$fields[0]);
  printf("%s\n",join("\t",@name,@fields[1..$#fields]));
}
close(F);
