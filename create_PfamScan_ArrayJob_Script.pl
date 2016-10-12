#!/usr/bin/env perl
#
# created on: 19/Jan/2012 at 14:30 by M.Alonso
#
# Creating an array job script for executing a PfamScan.
#
# Usage:
# ./script.pl jobname list_of_files.list numberoftasks
#


use strict;
use warnings;
use LoadFile;
use List::MoreUtils qw(uniq);


unless (defined $ARGV[0] && defined $ARGV[1] && defined $ARGV[2]){
  print "  Usage:\n";
  print "    ./thisscript.pl jobname inputfiles.list numberoftasks\n";
  exit;
}

## setupArrayJob2.py is a modified version of the original by RMosca
## Read header of setupArrayJob2.py to know more about the modification.
my $array_job_setup = "/home/malonso/phd/kinome/scripts/setupArrayJob2.py";

my $command_line = '/aloy/data/programs/PfamScan_24.0/assign_pfam_domains.py /aloy/data/programs/PfamScan_24.0/pfam_scan.pl /aloy/data/dbs/pfam/Pfam24.0/ \$i \$i.pfamscan.out';

my $jobname=$ARGV[0];
my $files_list=$ARGV[1];
my $tasks_numb=$ARGV[2];

system("$array_job_setup -N $jobname -l $files_list -t $tasks_numb $command_line");
##############################


