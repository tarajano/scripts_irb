#!/usr/bin/env perl
#
# mapping ACs using the file "sprot_trembl_parsed_lines"
#
#
use strict;
use warnings;

my %ACstomap=();
my %sprot_trembl_parsed_lines=();
my @fields;

# target ACs
open(F,$ARGV[0]) or die; # list of ACs to map
while(<F>){
  chomp;
  $ACstomap{$_}='-';
}
print "... ACs file loaded\n";
close(F);

# loading file "sprot_trembl_parsed_lines"
open(F,$ARGV[1]) or die; #
while(<F>){
  chomp;
  @fields=split('\|',$_);
  if(defined $sprot_trembl_parsed_lines{$fields[1]}){
    print "$fields[1] primary AC duplicated\n";
    # do something if duplicated Primary AC ??
  }else{$sprot_trembl_parsed_lines{$fields[1]}=[split(";",$fields[2])];}
  
}
print "... sprot_trembl file loaded\n";
close(F);

#print "$_\t$sprot_trembl_parsed_lines{$_}\n" foreach(keys %sprot_trembl_parsed_lines);

# mapping
open(OUT,">mappingresults.out") or die;
print "... mapping\n";
foreach my $key (keys %sprot_trembl_parsed_lines){
  
  foreach my $ac (keys %ACstomap){
    my $flag=0;
    foreach my $secondac (@{$sprot_trembl_parsed_lines{$key}}){
      if($secondac eq $ac){
      $ACstomap{$ac}=$key;
      $flag++; last;
      }
    }
  }
}
print OUT "$_\t$ACstomap{$_}\n" foreach(keys %ACstomap);
close(OUT);
#





