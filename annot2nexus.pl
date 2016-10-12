#!/usr/bin/env perl
#
#
#
# ./script annotationfile nexusfile
#
use strict;
use warnings;


my %tip_rename;     # hash containing the attributes values for each tip
my @attrib_names;   # labels for tips and attributes

################
## Reading tab-delimited file with tip names and attributes values.
## Include a first line with the attributes names.
## taxa    attrib1 attrib2
## Tip1    1.0     1.0
## Tip2    2.0     2.0
##
open(I,$ARGV[0]) or die "provide annotations file\n";
my $flag=0;
while(<I>){
  chomp;
  if($flag>0){
    ## retrieving the tip's names and attributes' values
    my ($tipname,@attrib_values) = split("\t",$_);
    my $new_tipname;
    ## constructing the string with attributes names and values
    foreach (my $i=0;$i<=$#attrib_names;$i++){
      $new_tipname= $new_tipname."\&$attrib_names[$i]=$attrib_values[$i],";
    }
    # removing last ","
    chop($new_tipname);
    $new_tipname = $tipname."\[".$new_tipname."\]";
    ## storing the new tip name 
    $tip_rename{$tipname}=$new_tipname;
  }else{
    ## retrieving the attributes names from the first row on annotation file
    ## tiplabel, (attrib1,attrib2,attribX,..)
    my $tipname;
    ($tipname,@attrib_names) = split("\t",$_);
    #print "$tipname\t@attrib_names\n";
    $flag++;
  }
}
close(I);
#print "$_\t$tip_rename{$_}\n" foreach (sort keys %tip_rename);
## tip_rename{tip_current_name}=tip_new_name
################


################
open(F,$ARGV[1]) or die "gimme a the nexus file\n";
while(<F>){
  my $line = $_;
  foreach my $otu (keys %tip_rename){
    $line =~ s/$otu/$tip_rename{$otu}/;
  }
  print "$line";
}
close(F);
################



################
## print tip_rename hash to translation file
#open(O, ">translation_file.txt") or die "can not create translation file\n";
#print O "$_\t$tip_rename{$_}\n" foreach (sort keys %tip_rename);
#close(O);
################

################
## Renaming OTUs in original file and saving to a new nexus file
#system("nextool.pl $ARGV[1] $ARGV[1].renamed rename_otus translation_file.txt");
################

#################
### reading the nexus file
#use Bio::NEXUS;
#my $treefile="/home/malonso/Desktop/coloringtrees/test.nex";
#die "provide the path to tree in nexus format\n" unless (-e $treefile);
#my $nexus = new Bio::NEXUS($treefile);
#################



















