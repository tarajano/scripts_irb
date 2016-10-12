#!/usr/bin/env perl
#
# mapping acs to go terms
# ./ACtoGO.pl acs.list /aloy/data/dbs/GO/gene_association.goa_human
#
use strict;
use warnings;
use List::MoreUtils qw(uniq);

my @ac;
my @goa_human;
my @fields;
my %ac_go;
my ($goid,$golab);

##
open(F,$ARGV[0])or die; # provide the file with the AC
@ac=<F>;
chomp(@ac);
close(F);
##
open(F,"/aloy/data/dbs/GO/gene_association.goa_human")or die; #
while(<F>){
  @fields=split("\t",$_);
  if($fields[0] eq "UniProtKB"){
    ($golab,$goid)=split(":",$fields[4]);
    my $ac=$fields[1];
    # load AC -> GO mapping if the AC has a  "protein phosphatase activity"-related Go term
    push(@{$ac_go{$ac}},$goid) if ($goid eq "0004721" || $goid eq "0004722" || $goid eq "0004725"  || $goid eq "0006470" || $goid eq "0008138");
  }
}
close(F);
##
##print "$_ @{$ac_go{$_}}\n" foreach(keys %ac_go);
$ac_go{$_}=[uniq(@{$ac_go{$_}})] foreach(keys %ac_go);

foreach(@ac){
  if (exists $ac_go{$_}){
    print "$_\t@{$ac_go{$_}}\n";
  }else{
    print "$_\t-\n";
  }
}
