#!/usr/bin/env perl
#
# created on: 10/Aug/2011 by M.Alonso
#
#
# TGZing folders in current directory
#
#
use strict;
use warnings;

my @folders = grep -d, <./*>;

foreach(@folders){
  my ($dor,$folder)=split("/", $_);
  # create a tgz file of the current folder
  print "TGZing folder $folder\n"; system("tar czf $folder.tgz $folder");
  # remove the current folder
  print "Removing folder $folder\n"; system("rm -rf $folder");

}





