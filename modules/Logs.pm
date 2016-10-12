# created on: 03/Jan/2012 by M.Alonso
#
# USAGE:
#   PERL5LIB env variable:
#    update PERL5LIB variable in .bashrc
#    export PERL5LIB=${PERL5LIB}:/home/malonso/phd/kinome/scripts/modules/
#
# CALLING MODULE
#   use Logs;
#
# Returns log2 or log10 for a given number.
#
#
#

use strict;
use warnings;

require Exporter;
package Logs;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(log2 log10);    # Symbols to be exported by default

#############
sub log2 {
  my $n = shift;
  return log($n)/log(2);
}
#############

#############
sub log10 {
  my $n = shift;
  return log($n)/log(10);
}
#############

1;
