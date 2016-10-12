#!/usr/bin/env perl
#
# created on: 26/Apr/2012 at 10:12 by M.Alonso
#
# Maps Uniprot ACs to Uniprot IDs using a uniprot_parsed_lines file
#
#
#

use strict;
use warnings;

use LoadFile;

my($ac, $id, $tmp, $input_file_number_of_columns);

my (@fields, @tmp, @target_columns);

my @input_file; ## [ line1, line2 ]
my @output_file; ## [ line1, line2 ]

my %map_ac2id;

##############################
### Printing help if no input file is provided or if -h is provided as input.
if (! defined $ARGV[0] or $ARGV[0] eq '-h'){
  print "Usage:\n";
  print "  \$ uniprot_ac2id.pl input.tab\n";
  print "\n";
  print "Remember you will have to provide the column(s) numbers\n";
  print "of the fields you want to convert from uniprot AC to ID.\n";
  print "\n";
  print "The script will produce an output file with ACs converted to IDs.\n";
  print "\n";
  exit;
}
##############################


##############################
## Loading input file.
## Must be a tab-delimited file.
my $inputfile = $ARGV[0];
print "\nLoading input file\n";
@input_file = File2Array($inputfile);

$input_file_number_of_columns = input_file_number_of_columns($input_file[0]);
##############################

##############################
## Columns to change from Uniprot AC to ID
## Request from the user what columns of the input file
## she/he wants to change from AC to ID.
print "\nWhat columns of input file you want to map from ACs to IDs?\n";
print "Please provide column(s) number(s) (space separated): ";
$tmp = <STDIN>;
chomp($tmp);
$tmp =~ s/\s+/ /g;
@target_columns = split(" ", $tmp);
die "Script died. There is at least one column out of file range !!\n" if( grep {$_ > $input_file_number_of_columns} @target_columns);
##############################

#############################
## Loading Uniprot_parsed_lines file
## 1433B_HUMAN|P31946|P31946;A8K9K2;E1P616| etc
print "Loading Uniprot_parsed_lines file\n";
foreach(File2Array("/aloy/home/malonso/phd_proj_dbs/uniprot/uniprot_2011_11/sprot_HUMAN_parsed_lines")){
  @fields  = split('\|', $_);
  ($id, $tmp) = splitunderscore($fields[0]);
  $ac=$fields[1];
  $map_ac2id{$ac}=$id;
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
  open(O, ">$inputfile.ac2id") or die;
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
      $fields[$col] = $map_ac2id{$fields[$col]} if (exists $map_ac2id{$fields[$col]});
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


