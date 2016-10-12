#!/usr/bin/env perl
#
# created on: 21/Sep/2012 at 12:16 by M.Alonso
# 
# Finds canonical Uniprot ACs in a file and converts them to uniprot ID
# The input file does not need to be of any a particular format. Just a flat file.
# Uniprot ACs must be surronded by space-type characters.
# 
# Usage:
# ./script pathtoinputfile
# 
# Output
# pathtoinputfile.ac2id
# 
# 

use strict;
use warnings;
#use Data::Dumper; # print Dumper myDataStruct
#use Statistics::R;
use List::MoreUtils qw(uniq);

use LoadFile;
use UniprotTools;

##############################
my $infile = $ARGV[0];
my $outfile = $infile.".ac2id";

my ($flag_is_uniprotAC, $id);
my (@fields);
##############################

##############################
### Loading the mapping data
my %uniprot_AC2ID_hash = %{ load_uniprot_AC2ID_hash() };
##############################

##############################
### Performing mapping
print "Performing AC2ID mappings in all fields of the input file\n";

open(O,">$outfile") or die;
foreach(File2Array($infile,0,"NOCOMMCHAR")){
  ### Splitting on any space-type character
  @fields = splitspaces($_);
  
  ### Print comment lines as they are
  if ($fields[0] =~ /^#/ ){ printf O "$_\n"; next; }
  
  for (my $i=0; $i<=$#fields; $i++){
    ### Save current string if it is likely to be a canonical uniprot AC
    $flag_is_uniprotAC = is_canonical_uniprotAC($fields[$i]);
    
    ### If current string is likely to be an uniprot AC AND it exists in the mapping hash, then 
    ### convert the current field in the file to the corresponding uniprot id.
    if( $flag_is_uniprotAC == 1 && exists $uniprot_AC2ID_hash{$fields[$i]} ){
      $id = $uniprot_AC2ID_hash{$fields[$i]};
      $fields[$i] = $id;
    }
  }
  printf O ("%s\n", jointab(@fields));
}
close(O);
##############################








