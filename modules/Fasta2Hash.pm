# created on: 17/Mar/2011 by M.Alonso
#
# USAGE:
#   PERL5LIB env variable:
#    update PERL5LIB variable in .bashrc
#    export PERL5LIB=${PERL5LIB}:/home/malonso/phd/kinome/scripts/modules/
#
# CALLING MODULE
#   use LoadFile;
#

use strict;
use warnings;

require Exporter;
package Fasta2Hash;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(Fasta2Hash);    # Symbols to be exported by default

#############
## Creating a single string from the fasta sequence and 
## creating a hash key->Seq for every entry
## INPUT: array containing a fasta file
## OUTPUT: hash{key}=sequence
##
sub Fasta2Hash{
  my @array = @_;
  chomp(@array);
  my %hash; my $seq=""; my $key="";
  
  ##
  foreach my $line (@array){
    #if($line =~ /^>/){
    if($line =~ /^>(\S+)/){
      if($key eq ""){;}
      elsif($key ne ""){
        $hash{$key}=$seq;
        $seq="";
      }
      #$key=$line;
      $key=$1;
    }elsif($line =~ /^[A-Za-z]/){
      $seq=$seq.$line;
    }else{;}
  }
  $hash{$key}=$seq;
  ##
  return %hash;
}
#############
1;
