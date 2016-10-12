#!/usr/bin/env perl 
#
# compare the content of two files line by line 
#
# script QUERY_LIST SUBJECT_LIST
# 
# Usage:
#
#   ./thisscript [I|C] Qcol Rcol Qfile  Rfile
# 
#     I: INTERSECTION of two sets (elements present in both lists Query and Reference lists)
#     C: COMPLEMENT of Query list (elements of Query list NOT PRESENT in Reference list)
#     Qcol: Column to be considered in the Query file (Default = 1)
#     Rcol: Column to be considered in the Reference file (Default = 1)
#     Qfile: File containing the list of Query elements
#     Rfile: File containing the list of Reference elements
# 
# Requirements:
# Input files must be space-delimited (either spaces or tabs).
# If a column number is specified for one of the input files, then it must also be specified for the other file.
# 
# 
# 

use strict;
use warnings;
use List::MoreUtils qw(uniq);
use Scalar::Util::Numeric qw(isint);
use List::Compare qw(get_complement get_intersection);

use LoadFile;

my ($intersection_complement, $Qcol, $Rcol, $Qfile, $Rfile);

my %query_list;
my %subject_list;
my (@fields, @tmp, @intersection, @Qcomplement);

##############################
### Checking arguments provided 

### If no arguments are provided, print the help
exit_on_bad_arguments() if(! defined $ARGV[0]);

### Check for INTERSECTION | COMPLEMENT argument
if($ARGV[0] eq "I" || $ARGV[0] eq "C" ){
  $intersection_complement = $ARGV[0];
}else{exit_on_bad_arguments($ARGV[0]);}

if( 5 == scalar @ARGV && isint($ARGV[1]) && isint($ARGV[2] && -e $ARGV[3] && -e $ARGV[4])){
  ### If five arguments are provided, check that the 1st and 2nd are
  ### proper integers and that 3th and 4th are existing files.
  ### These are the columns to be analyzed in the provided files.
  $Qcol = $ARGV[1];
  $Rcol = $ARGV[2];
  $Qfile = $ARGV[3];
  $Rfile = $ARGV[4];
  print ("ok\n");
  @intersection = @{ compare_lists($intersection_complement, $Qcol, $Rcol, $Qfile, $Rfile) };
  print_result(\@intersection, $intersection_complement);
}elsif( 3 == scalar @ARGV && -e $ARGV[1] && -e $ARGV[2]){
  ### If three arguments are provided, set COL-QFILE and COL-RFILE to default value (1)
  ### First columns of the provided files will be analyzed.
  ### Check that arguments 1 and 2 are files and that they exists.
  $Qcol = 1;
  $Rcol = 1;
  $Qfile = $ARGV[1];
  $Rfile = $ARGV[2];
  @Qcomplement = @{ compare_lists($intersection_complement, $Qcol, $Rcol, $Qfile, $Rfile) };
  print_result(\@Qcomplement, $intersection_complement);
}else{exit_on_bad_arguments($ARGV[1], $ARGV[2]);}


##############################

##############################
######## SUBROUTINES #########
##############################

##############################
### Printing results
### 
### print_result(\@compare_lists_results)
### 
### 
sub print_result{
  use Cwd;
  
  ### Get current working directory
  my $pwd = cwd();
  
  my @res = @{$_[0]};
  my $intersection_complement = $_[1];
  my $resfilename;
  if($intersection_complement eq "I"){
    $resfilename = $pwd."/"."Intersection.list";
    printf ("The size of the intersection is: %d\n", scalar @res);
  }elsif($intersection_complement eq "C"){
    $resfilename = $pwd."/"."Qcomplement.list";
    printf ("The size of the Query complement is: %d\n", scalar @res);
  }else{print "Wrong intersection_complement argument\n"; die;}
  
  if(0 < scalar @res){
     printf ("The complete list is in the file: %s\n", $resfilename);
    open(O, ">$resfilename") or die;
    foreach(sort {$a cmp $b} @res){print O "$_\n";}
    close(O);
  }
}
##############################

##############################
### Compare lists.
### Gets either the Intercept or the Complement for the query
### 
### compare_lists(I|C,Qcol,Rcol,Qfilepath,Rfilepath)
### 
### Returns:
### A reference to an array
### 
sub compare_lists{
  my ($intersection_complement, $Qcol, $Rcol, $Qfile, $Rfile) = @_;
  $Qcol--; $Rcol--; ### Converting col number to array indexes
  my $list_compare;
  my (@fields, @Qlist, @Rlist, @intersection, @Qcomplement);
  
  ### Loading query file
  foreach(File2Array($Qfile)){
  @fields = splitspaces($_);
  push(@Qlist, $fields[$Qcol]);
  ###push(@Qlist, $fields[$Qcol]) if (defined $fields[XXX]);
  }
  @Qlist = uniq(@Qlist);
  
  ### Loading reference file
  foreach(File2Array($Rfile)){
  @fields = splitspaces($_);
  push(@Rlist, $fields[$Rcol]);
  ###push(@Rlist, $fields[$Rcol]) if (defined $fields[XXX]);
  }
  @Rlist = uniq(@Rlist);
  
  ### Creating the list compare object
  $list_compare = List::Compare->new('--unsorted', '--accelerated',\@Rlist, \@Qlist);
  
  ### Computing INTERSECTION or complement
  if($intersection_complement eq "I"){
    @intersection = $list_compare->get_intersection();
    return \@intersection;
  }elsif($intersection_complement eq "C"){
    @Qcomplement = $list_compare->get_complement();
    return \@Qcomplement;
  }else{print "Wrong intersection_complement argument\n"; die;}
}
##############################

##############################
sub exit_on_bad_arguments{
  print "
      Please, provide correct arguments to the script:

     ./thisscript [I|C] Qcol Rcol Qfile  Rfile

     I: INTERSECTION of Query and Reference lists
     C: COMPLEMENT of Query list (elements of Query NOT PRESENT Reference)
     Qcol,Rcol: Columns to be considered in the Query and Reference files (Default = 1)
     Qfile,Rfile: Files containing the list of Query and Reference elements

      Requirements:
      Input files must be space-delimited (either spaces or tabs)\n\n";
 exit;
}
##############################



