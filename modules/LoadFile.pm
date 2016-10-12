# created on: 17/Mar/2011 by M.Alonso
#
# USAGE:
#   PERL5LIB env variable:
#    update PERL5LIB variable in .bashrc
#    export PERL5LIB=${PERL5LIB}:/home/malonso/phd/kinome/scripts/modules/
#
# CALLING MODULE
#   use LoadFile;
#

use strict;
use warnings;

require Exporter;
package LoadFile;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(  File2Array
                      ZippedFile2Array
                      
                      splitat
                      splitdot
                      splittab
                      splitdash
                      splitpipe
                      splitequal
                      splitslash
                      splitcomma
                      splitspaces
                      splitsemicolon
                      splitunderscore
                      
                      joinat
                      jointab
                      joinpipe
                      joindash
                      joinslash
                      joincomma
                      joinsemicolon
                      joinunderscore
                      
                      files2array_by_extension
                      space_delimited_file_to_array
                      file_base_name_from_path
                    );    # Symbols to be exported by default
#

##############################
######## SUBROUTINES ######### 
##############################

##############################
## Returns the base name of a file given the full path to it.
## It assumes there is only one dot in the file name, the one before the file extension.
## 
## Input:
##  - Full path to file:
## 
## Returns:
##  - File base name
##    - e.g.: /path/to/filename.ext -> filename
## 
## Usage:
##  - filename = file_base_name_from_path(fullpath)
## 
sub file_base_name_from_path{
  my $path_to_file = $_[0] or die "   Please provide path to file in file_base_name_from_path()\n";
  
  my @files = splitslash($path_to_file);
  my @tmp = splitdot($files[-1]);
  my $base_name = $tmp[0];
  return $base_name;
}
##############################


##############################
## Loading space delimited file in an array.
## Each non-space string will be loaded into an element of the array. 
## 
## Input format e.g.:
## 1 1 1 1 1
## 1 1 1 1 1
## 1 1
## 
## Input: 
##  - full path to the file
##  - number of lines to be skept at the beggining of the file
##  - character that specifies comment lines
##  
##  Returns: 
##  - Ref. to array containing the input file.
##    - e.g.: [1,1,1,...]
##
##  Usage:
##  - @file = @{ space_delimited_file_to_array(fullpath, [skiplines], [comment_char]) }
##  
sub space_delimited_file_to_array{
  my $pathtofile=$_[0];
  my $skip_header = 0;
  my $comment_char="#";
  my @file;
  
  ## Set the second argument of the function (if needed)
  ## to the number of lines to be skept at the beggining of the file.
  $skip_header = $_[1] if(defined $_[1]); 
  
  ## The third argument of the function (defines the character that 
  ## specifies comment lines in the input file.
  $comment_char = $_[2] if(defined $_[2]); 
  
  open(I,$pathtofile) or die "Error: Couldn't open the file $pathtofile";
  while(<I>){
    ## Skipping first line (the uncommented header).
    if($skip_header > 0 ){$skip_header--; next;}
    chomp();
    ## Skipping all commented lines
    push(@file, splitspaces($_) ) if($_ !~ /^$comment_char/);
  }
  close(I);
  return \@file;
}
##############################


##############################
## Loading file into an array
## ARGV[0]: path to the file
## ARGV[1]: number of lines to be skept at the beggining of the file
## ARGV[2]: character that specifies comment lines
##
sub File2Array{
  my $pathtofile=$_[0];
  my $skip_header = 0;
  my $comment_char="#";
  my @file;
  
  ## Set the second argument of the function (if needed)
  ## to the number of lines to be skept at the beggining of the file.
  $skip_header = $_[1] if(defined $_[1]); 
  
  ## The third argument of the function (defines the character that 
  ## specifies comment lines in the input file.
  $comment_char = $_[2] if(defined $_[2]); 
  
  open(I,$pathtofile) or die "Error: Couldn't open the file $pathtofile";
  while(<I>){
    ## Skipping first line (the uncommented header).
    if($skip_header > 0 ){$skip_header--; next;}
    chomp();
    ## Skipping all commented lines
    push(@file,$_) if($_ !~ /^$comment_char/);
    #if($_ !~ /^$comment_char/){push(@file,$_)}else{print "$_\n";};
  }
  close(I);
  return @file;
}
##############################

##############################
## Loading zipped file into an array
## Usage: 
##  ZippedFile2Array(pathtofile)
## Returns:
##  a reference to an array
##
sub ZippedFile2Array{
  ## Libraries for reading compressed files
  use IO::Uncompress::AnyUncompress qw(anyuncompress $AnyUncompressError);
  use IO::File;
  
  my $pathtofile=$_[0];
  my ($gzippedfile, $buffer);
  my @buffer;
  
  ### Reading from a gzipped PDB file and loading the content in an array.
  $gzippedfile = new IO::File "<$pathtofile" or die " Cannot open $pathtofile $!\n";
  anyuncompress $gzippedfile => \$buffer or die " anyuncompress failed: $AnyUncompressError\n";
  @buffer = split("\n", $buffer);
  chomp(@buffer);
  return \@buffer;
}
##############################

##############################
## Splitting lines

sub splitequal{
  if(defined $_[0]){ return split('=', $_[0]); }
  else{ return split('@', $_); }
}

sub splitpipe{
  if(defined $_[0]){ return split('\|', $_[0]); }
  else{ return split('@', $_); }
}

sub splitat{
  if(defined $_[0]){ return split('@', $_[0]); }
  else{ return split('@', $_); }
}

sub splittab{
  if(defined $_[0]){ return split("\t", $_[0]); }
  else{ return split("\t", $_); }
}

sub splitslash{
  if(defined $_[0]){ return split('/', $_[0]); }
  else{ return split('/', $_); }
}

sub splitdash{
  if(defined $_[0]){ return split('-', $_[0]); }
  else{ return split('-', $_); }
}

sub splitdot{
  if(defined $_[0]){ return split('\.', $_[0]); }
  else{ return split('\.', $_); }
}

sub splitcomma{
  if(defined $_[0]){ return split(',', $_[0]); }
  else{ return split(',', $_); }
}

sub splitspaces{
  if(defined $_[0]){ return split('\s+', $_[0]); }
  else{ return split('\s+', $_); }
}

sub splitsemicolon{
  if(defined $_[0]){ return split(';', $_[0]); }
  else{ return split(';', $_); }
}

sub splitunderscore{
  if(defined $_[0]){ return split('_', $_[0]); }
  else{ return split('_', $_); }
}
##############################

##############################
## Joinning fields
sub joinat{return join('@', @_);}
sub jointab{return join("\t", @_);}
sub joinpipe{return join('|', @_);}
sub joindash{return join("-", @_);}
sub joinslash{return join('/', @_);}
sub joincomma{return join(",", @_);}
sub joinsemicolon{return join(";", @_);}
sub joinunderscore{return join("_", @_);}
##############################

##############################
### Creates an array with the paths to files.
### 
### Given a path to a directory and a file extension the function 
### loads to an array the full paths to each file.
### 
### Usage:
###   @files = @{  files2array_by_extension("/my/path/to/folder/", "ext")  } 
###   
### Input:
###   - path to files ( e.g.: /my/path/tofiles/ )
###   - file extension ( e.g.: txt )
### 
### Output:
###   - a reference to an array containing paths to files
### 
sub files2array_by_extension{
  my $path = $_[0];
  my $file_extension = $_[1];
  my (@fields,@paths_to_files);
  
  opendir (DIR, $path) or die;
  while (my $file = readdir(DIR)){
    
    ### Retrieve extension of current file 
    @fields = LoadFile::splitdot($file);
    ### Skip if current file has no file extension 
    next if (0 == scalar @fields);
    
    ### Check for files with the desired extension
    push(@paths_to_files, $path.$file) if($fields[-1] eq $file_extension);
  }
  close(DIR);

  return \@paths_to_files;
}
##############################

1;
