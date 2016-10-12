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
use LoadFile;

require Exporter;
package PrintDataStructure;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(  
                      print2file_HoA
                      print2files_HoA
                      print2file_HoAoA
                      print2files_HoAoA
                      
                      print2file_HoHoA
                      print2file_HoH_num
                      
                      print2file_hash_sort_value
                    );    # Symbols to be exported by default
#

##############################
######## SUBROUTINES ######### 
##############################

##############################
### This function prints to a single file the data structure: {k1}=[[],[]] (Hash of Array of Arrays, HoAoA)
### Each line of the output file (tab delimited) contains the key and a single element of the 2D array 
###   -e.g.:
###     - keyA element1
###     - keyA element2
###     - keyA element3
###     - keyB element1
###     - keyC element1
###     - keyC element2
### 
### Input:
###   - Ref. to HoAoA
###   - full path to output file (string).
###   - header for output file (string )
### 
### Output:
###   - tab-delimited file
### 
### Usage:
###   print2files_HoAoA(\%HoAoA, "/path/to/outdirectory/outfile", "outfileheader")
### 
sub print2file_HoAoA{
  my @args = @_;
  if(3 != scalar @args){print "    Check number of arguments for print2files_HoA(\%HoAoA, /path/to/outdirectory/, header)\n"; exit;}
  
  ### Grabbing arguments
  my %hoaoa = %{$args[0]};
  my $outfile_path = $args[1];
  my $header = $args[2];
  
  open(O, ">$outfile_path") or die "Can not create output file: $outfile_path\n";
  print O "$header\n";
  foreach my $key (keys %hoaoa){
    foreach ( @{$hoaoa{$key}} ){
      printf O ( "%s\n", LoadFile::jointab($key, @{$_}) );
    }
  }
  close(O);
}
##############################

##############################
### This function prints to files the data structure: {k1}=[[],[]] (Hash of Array of Arrays, HoAoA)
### The function uses the key as the name of the output file and 
### prints the array in the corresponding file.
### 
### Input:
###   - Ref. to HoAoA
###   - full path to output directoy (string).
###   - header for output file (string )
### 
### Output:
###   - tab-delimited file
### 
### Usage:
###   print2files_HoAoA(\%HoAoA, "/path/to/outdirectory/", "outfileheader")
### 
sub print2files_HoAoA{
  my @args = @_;
  if(3 != scalar @args){print "    Check number of arguments for print2files_HoA(\%HoAoA, /path/to/outdirectory/, header)\n"; exit;}
  
  ### Grabbing arguments
  my %hoaoa = %{$args[0]};
  my $dir_path = $args[1];
  my $header = $args[2];
  
  my ($path2outfile, $string);
  
  foreach my $key (keys %hoaoa){
    $path2outfile = $dir_path.$key.".out";
    open(O, ">$path2outfile") or die "Can not create output file: $path2outfile\n";
    print O "$header\n";
    foreach ( @{$hoaoa{$key}} ){
      printf O ( "%s\n", LoadFile::jointab(@{$_}) );
    }
    close(O);
  }
}
##############################

##############################
### This function prints to a file the data structure: {k1}=SCALAR
### Before printing, the function sorts values by alphabetic|numeric order.
### The function prints the key and the corresponding scalar to a 
### tab-delimited file.
### 
### Input:
###   - ref. to data structure {k}=scalar
###   - scalar type: NUM | STR
###   - sort order: DEC reasing or INC reasing values
###   - full path to outputfile (string).
###   - header string for output file (must be already tab delimited)
### 
### Output:
###   - tab-delimited file
### 
### Usage:
###   print2file_HoA(\%hoh, "NUM"|"STR", "DEC"|"INC", "/path/to/my/out/file", "outfileheader")
### 
sub print2file_hash_sort_value{
  my @args = @_;
  if(5 != scalar @args){print "    Check number of arguments for print2file_HoA(\%hoh, NUM|STR, DEC|INC, /path/to/my/out/file, outfileheader)\n"; exit;}
  
  ### Grabbing arguments
  my %hash = %{$args[0]};
  my $sort_type = $args[1];
  my $sort_order = $args[2];
  my $outfile_path = $args[3];
  my $outfile_header = $args[4];
  my ($k);
  
  ### Checking for proper sorting parameters
  if($sort_type ne "NUM" && $sort_type ne "STR" ){ print "Invalid argument for the sorting type: [NUM | STR]\n"; exit;}
  if($sort_order ne "DEC" && $sort_order ne "INC" ){ print "Invalid argument for the sorting order: [DEC | INC]\n"; exit;}
  
  
  open(O, ">$outfile_path") or die;
  printf O ("%s\n", $outfile_header);
  
  ### Selecting NUMeric or STRing sort
  ### Selecting DECremental or INCremental sort
  if($sort_type eq "NUM"){ ### If NUMeric sort
    if($sort_order eq "DEC"){ ### If DECremental sort
      foreach $k ( sort { $hash{$b} <=> $hash{$a} } keys %hash ){
        printf O ("%s\n", LoadFile::jointab($k, $hash{$k} ));
      }
    }else{ ### If INCremental sort
      foreach $k ( sort { $hash{$a} <=> $hash{$b} } keys %hash ){
        printf O ("%s\n", LoadFile::jointab($k, $hash{$k} ));
      }
    }
  }else{ ### If STRing sort
    if($sort_order eq "DEC"){ ### If DECremental sort
      foreach $k ( sort { $hash{$b} cmp $hash{$a} } keys %hash ){
        printf O ("%s\n", LoadFile::jointab($k, $hash{$k} ));
      }
    }else{ ### If INCremental sort
      foreach $k ( sort { $hash{$a} cmp $hash{$b} } keys %hash ){
        printf O ("%s\n", LoadFile::jointab($k, $hash{$k} ));
      }
    }
  }
  
  close(O);
}
##############################

##############################
### This function prints to files the data structure: {k1}=[array]
### The function uses the key as the name of the output file and 
### prints the array in the corresponding file.
### 
### Input:
###   - Ref. to hash of array
###   - full path to output directoy (string).
###   - header for output file (string )
### 
### Output:
###   - tab-delimited file
### 
### Usage:
###   print2files_HoA(\%hoh, "/path/to/outdirectory/", "outfileheader")
### 
sub print2files_HoA{
  
  my @args = @_;
  if(3 != scalar @args){print "    Check number of arguments for print2files_HoA(\%hoa, /path/to/outdirectory/, header)\n"; exit;}
  
  ### Grabbing arguments
  my %hoa = %{$args[0]};
  my $dir_path = $args[1];
  my $header = $args[2];
  my ($k, $path2outfile);
  
  
  foreach my $key (keys %hoa){
    $path2outfile = $dir_path.$key.".out";
    open(O, ">$path2outfile") or die "Can not create output file: $path2outfile\n";
    print O "$header\n";
    foreach ( @{$hoa{$key}} ){ print O "$_\n"; }
    close(O);
    
  }
}
##############################

##############################
### This function prints to a file the data structure: {k1}=[array]
### The function sorts keys by alphabetic order before printing.
### The function prints the key and the corresponding array to a 
### tab-delimited file.
### 
### Input:
###   - ref. to data structure {k}=[array]
###   - sort order: DEC reasing or INC reasing values
###   - full path to outputfile (string).
###   - header string for output file OPTIONAL (if present, must be already tab delimited)
### 
### Output:
###   - tab-delimited file
###     format: key arrayelement1 arrayelement2 arrayelementN
### 
### 
### Usage:
###   print2file_HoA(\%hoh, "DEC", "/path/to/my/out/file", outfileheader)
### 
sub print2file_HoA{
  
  my @args = @_;
  if(3 > scalar @args){print "    Check number of arguments for print2file_HoA(ref %hoa, DEC, /path/to/out/file, outfileheader)\n"; exit;}
  
  ### Grabbing arguments
  my %hoa = %{$args[0]};
  my $sort_order = $args[1];
  my $outfile_path = $args[2];
  my $outfile_header = $args[3] if(defined $args[3]);
  my ($k);
  
  open(O, ">$outfile_path") or die;
  printf O ("%s\n", $outfile_header) if(defined $outfile_header);
  
  if($sort_order eq "DEC"){
    foreach $k ( sort { $hoa{$b} cmp $hoa{$a} } keys %hoa ){ printf O ("%s\n", LoadFile::jointab($k, @{$hoa{$k}} )); }
  }elsif($sort_order eq "INC"){
    foreach $k ( sort { $hoa{$a} cmp $hoa{$b} } keys %hoa ){ printf O ("%s\n", LoadFile::jointab($k, @{$hoa{$k}} )); }
  }else{
    print "Invalid argument for the sorting: [DEC | INC]\n"; exit;
  }
  
  close(O);
}
##############################

##############################
### This function prints to a file the data structure: {k1}{k2}=scalar
### where k1, k2 are hash keys and scalar is a number.
### The function sorts by value before printing.
### The function prints each pair of keys and the corresponding value
### to a tab-delimited file.
### 
### Input:
###   - ref. to data structure {k}{k}=value
###   - sort order: DECreasing or INCreasing values
###   - full path to outputfile (string).
###   - header string for output file (should be already tab delimited)
### 
### Output:
###   - tab-delimited file
### 
### Usage:
###   print2file_HoH_num(\%hoh, "DEC", "/path/to/my/out/file.tab", outfileheader)
### 
sub print2file_HoH_num{
  my @args = @_;
  if(4 != scalar @args){print "    Check number of arguments for print2file_HoH_num()\n"; exit;}
  
  ### Grabbing arguments
  my %hoh = %{$args[0]};
  my $sort_order = $args[1];
  my $outfile_path = $args[2];
  my $outfile_header = $args[3];
  
  my ($k1, $k2);
  my %new_hoh;

  ### For sorting based on value you need to first merge the keys.
  foreach $k1 ( keys %hoh ){
    foreach $k2 ( keys %{$hoh{$k1}} ){
      $new_hoh{LoadFile::jointab($k1, $k2)} = $hoh{$k1}{$k2};
    }
  }
  
  open(O, ">$outfile_path") or die;
  printf O ("%s\n", $outfile_header);
  if($sort_order eq "DEC"){
    foreach $k1 ( sort { $new_hoh{$b} <=> $new_hoh{$a} } keys %new_hoh ){ printf O ("%s\n", LoadFile::jointab($k1, $new_hoh{$k1})); }
  }elsif($sort_order eq "INC"){
    foreach $k1 ( sort { $new_hoh{$a} <=> $new_hoh{$b} } keys %new_hoh ){ printf O ("%s\n", LoadFile::jointab($k1, $new_hoh{$k1})); }
  }else{
    print "Invalid argument for the numeric sorting: [DEC | INC]\n"; exit;
  }
  close(O);
}
##############################

##############################
### This function prints to a file the data structure: {k1}{k2}=@arra (hash of hash of array)
### The function prints each pair of keys and the corresponding value
### to a tab-delimited file.
### 
### Input:
###   - ref. to the data structure %HoHoA
###   - full path to outputfile (string).
###   - header string for output file (should be already tab delimited)
### 
### Output:
###   - tab-delimited file
### 
### Usage:
###   print2file_HoHoA(\%hohoa, '/path/to/my/out/file.tab', 'outfileheader')
### 
sub print2file_HoHoA{
  my @args = @_;
  if(3 != scalar @args){print "    Check number of arguments for print2file_HoHoA()\n"; exit;}
  
  ### Grabbing arguments
  my %hohoa = %{$args[0]};
  my $outfile_path = $args[1];
  my $outfile_header = $args[2];
  
  open(O, ">$outfile_path") or die;
  printf O ("%s\n", $outfile_header);
  foreach my $k1 (keys %hohoa){
    foreach my $k2 (keys %{$hohoa{$k1}}){
      printf O ("%s\n", LoadFile::jointab($k1, $k2, @{$hohoa{$k1}{$k2}}));
    }
  }
  close(O);
}
##############################


1;
