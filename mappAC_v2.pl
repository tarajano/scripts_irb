#!/usr/bin/env perl
#
# Created by MAlonso on 2010-11-12
#
# mapping ACs using the file "sprot_trembl_parsed_lines"
#
#
#
#
#
#


use strict;
use warnings;

my @fields;
my @secACs;

my %ACstomap=();
my %redundant_mapp=();
my %sprot_trembl_parsed_lines=();


###############
## load ACs to be mapped
open(F,$ARGV[0]) or die; # list of ACs to map
while(<F>){
  chomp;
  $ACstomap{$_}='-';
}
print "... ACs file loaded\n";
close(F);
###############

###############
# loading file "sprot_trembl_parsed_lines"
open(F,$ARGV[1]) or die; # /aloy/data/dbs/uniprot/uniprot_versionXX
while(<F>){
  chomp;
  @fields=split('\|',$_);
  @secACs=split(";",$fields[2]);
  
  if(@secACs == 0){
    #if (defined $sprot_trembl_parsed_lines{$fields[1]}){
      #print "secondayAC $fields[1] already assigned\n";
    #}else{#$sprot_trembl_parsed_lines{$fields[1]}=$fields[1];#}
    unless (defined $sprot_trembl_parsed_lines{$fields[1]}){
      $sprot_trembl_parsed_lines{$fields[1]}=$fields[1];
    }
  }else{
    foreach(@secACs){
      #if(defined $sprot_trembl_parsed_lines{$_}){
        ##print "SecondayAC $_ already mapped to $sprot_trembl_parsed_lines{$_}. Ommiting new mapping to $fields[1]\n";    
      #}else{#$sprot_trembl_parsed_lines{$_}=$fields[1];#}
      unless (defined $sprot_trembl_parsed_lines{$_}){
        $sprot_trembl_parsed_lines{$_}=$fields[1]; # {secAC}=primAC
      }
    }
  }
}
print "... sprot_trembl file loaded\n";
close(F);
###############
#print "$_\t$sprot_trembl_parsed_lines{$_}\n" foreach(keys %sprot_trembl_parsed_lines);

###############
## performing mapping
print "... mapping\n";
foreach my $oldac (keys %ACstomap){
  $ACstomap{$oldac}=$sprot_trembl_parsed_lines{$oldac} if(exists $sprot_trembl_parsed_lines{$oldac});
}
print "... printing mapping\n";
open(OUT,">mappingresults.out") or die;
print OUT "#ACtomap\t#ACmapped\n";
print OUT "$_\t$ACstomap{$_}\n" foreach(sort {$a cmp $b} keys %ACstomap);
close(OUT);
###############





