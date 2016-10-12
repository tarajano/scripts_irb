#!/usr/bin/env perl
#
# created on: 20/Jul/2012 at 15:22 by M.Alonso
# 
# Given an input file, the script maps 
# Uniprot ACs to GeneIDs of specified columns
#
#

use strict;
use warnings;

use LoadFile;

my($ac, $id, $tmp, $input_file_number_of_columns);

my (@fields, @tmp, @target_columns);

my @input_file; ## [ line1, line2 ]
my @output_file; ## [ line1, line2 ]

my %map_ac2geneid;


##############################
## Loading input file.
## Must be a tab-delimited file.
my $inputfile = $ARGV[0];
print "\nLoading input file\n";
@input_file = File2Array($inputfile);

$input_file_number_of_columns = input_file_number_of_columns($input_file[0]);
##############################

##############################
## Columns to change from Uniprot AC to GeneID
## Request from the user what columns of the input file
## she/he wants to change from AC to GeneID.
print "\nWhat columns of input file you want to map from ACs to GeneIDs?\n";
print "Please provide column(s) number(s) (space separated): ";
$tmp = <STDIN>;
chomp($tmp);
$tmp =~ s/\s+/ /g;
@target_columns = split(" ", $tmp);
die "Script died. There is at least one column out of file range !!\n" if( grep {$_ > $input_file_number_of_columns} @target_columns);
##############################

#############################
## Loading AC 2 GeneID mapping file
print "Loading Uniprot AC to GeneID mapping file\n";
foreach(File2Array("/aloy/home/malonso/phd_proj_dbs/human_proteome/humanproteome.ac2geneid",1)){
  @fields  = splittab($_);
  $map_ac2geneid{$fields[0]}=$fields[1];
}
#############################

##############################
## Mapping
print "Mapping ACs to IDs\n";
@output_file = @{mapping_ac2id()} ;

## Printing out
print "Printing out\n";
print_mapped_file();
##############################


##############################
######## SUBROUTINES #########
##############################

##############################
## Printing output file
sub print_mapped_file{
  open(O, ">$inputfile.ac2geneid") or die;
  print O "$_\n" foreach (@output_file);
  close(O)
}
##############################

##############################
sub mapping_ac2id{
  ## Converting target columns numbers to indexes.
  my @taget_columns_idx = map{$_ - 1} @target_columns;
  my @fields;
  my @mapped;
  
  foreach my $line (@input_file){
    @fields = splittab($line);
    
    ## Mapping ACs in each column.
    foreach my $col (@taget_columns_idx){
      $fields[$col] = $map_ac2geneid{$fields[$col]} if (exists $map_ac2geneid{$fields[$col]});
    }
    ## Filling output array
    push(@mapped, jointab(@fields));
  }
  return \@mapped;
}
##############################


##############################
## Retrieving number of columns
## in input file.
sub input_file_number_of_columns{
  my @cols = splittab($_[0]);
  my $cols = scalar @cols;
  return $cols;
}
##############################








