#!/usr/bin/perl 
#
# created on: 28/Feb/2011 by M.Alonso
# drawing circles on Manning tree for the PKs responsible for a P+Event (as of hprd9)
# 
#
#

use DBI;
use warnings;
use strict;
use Image::Magick;

## manning tree
#Image Type: png
#Width: 992 pixels
#Height: 1300 pixels

my ($x,$y);
my %hpk_coords;
my (@fields,@hpk_ptm);


##################
## Reading Image File
my $image = Image::Magick->new;
open(IMAGE, "/home/malonso/phd/kinome/hpk/ePKtree/tree_pics/hpk_tree_manning_ePK_aPK.png");
$image->Read(file=>\*IMAGE);
close(IMAGE);
##################

##################
## Reading HPK-Coordinates File
open(I,"/home/malonso/phd/kinome/hpk/mapping_uniprotID_manning-name_UniprotAC_coord.tab") or die;
while(<I>){
  ## AAK1_HUMAN AAK1  Q2M2I8  312,766
  chomp();
  @fields = split('\t+',$_);
  ($x,$y) = split(",",$fields[3]);
  $hpk_coords{$fields[1]}=[$x,$y]; ## {hpk_name}=[x,y]
}
close(I);
##################

##################
## Loading phosphorylation data to plot
my $conn = DBI->connect("dbi:Pg:dbname=hprd_ptm_db;host=localhost;port=5433;user=malonso;password='manuel'") or die;
## Fetch HPKs in hprd9 that are reponsible for a P+Event and that also has been mapped to Manning name
my $hpks = $conn->prepare("SELECT distinct(hpkd_name) FROM manning2hprdid")or die $conn->errstr;
$hpks->execute() or die $conn->errstr;
while(my @row = $hpks->fetchrow_array()){
  push(@hpk_ptm,$row[0]);
  #print "$row[0]\n";
}
$hpks->finish;
$conn->disconnect();
##################

###################
## Writing circles to loaded image
foreach (@hpk_ptm){
  if(exists $hpk_coords{$_}){
    ($x,$y)=($hpk_coords{$_}[0],$hpk_coords{$_}[1]);
    $image->Draw(stroke=>'black', fill=>'green',primitive=>'circle', x=>$x, y=>$y, points=>'0,0,4,0');
  }
}
###################

##################
## Opening and writing to output image File
my $filename = "hpk_tree_manning_ePK_aPK_hprd9_phosphorylations.png";
open(IMAGE, ">$filename");
$image->Write(file=>\*IMAGE, filename=>$filename);
close(IMAGE);
##################









