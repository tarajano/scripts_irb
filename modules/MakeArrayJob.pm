# created on: 14/Mar/2011 by M.Alonso
#
# Module for generating Array Jobs using R'Mosca "setupArrayJob.py" script
#
# INPUT:
#  
#  
#  
# OUTPUT:
#  
# 
# USAGE:
# You must include the following in the calling script:
#   use lib "$ENV{HOME}/phd/kinome/scripts/modules"; # path to this module
#   use THISMODULESNAME;
# 

use strict;
use warnings;

require Exporter;
package MakeArrayJob;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(makearrayjob);    # Symbols to be exported by default

#######################
## USAGE:
## 
sub MakeArrayJob{
  my $jobname = $_[0];
  my $listfile = $_[1];
  my $tasks = $_[2];
  my $executable = $_[3];
  my $ = $_[4];
  my $ = $_[5];
  my $ = $_[6];
  
  #setupArrayJob.py -N blastbac -l list_of_seq_files.txt -t 3 blastpgp -i seq1.fas -d GNB_proteomes_fasta_files_MERGED.fas -o outputfile1.out -e 1e-5
  system("/home/malonso/AntiPathoGN/myscripts/setupArrayJob.py");
  
}
#######################


1;
