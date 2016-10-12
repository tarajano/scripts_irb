#!/usr/bin/env perl
#
# plotting the avg of hpkd lenght per hpkd family
#
# usage: 
# /script
#
# input:
# hpkd_db, gnuplot_template_file
#
# output:
# gnuplot_data_file, gnuplot_script_file, histogram.eps
#

use strict;
use warnings;
use DBI;

my $index=0;
my $xtics_labels="";
my ($query,$group,$family);

my @row;
my @PKgroups=("AGC","CAMK","CK1","CMGC","Other","RGC","STE","TK","TKL","Atypical");

my %hash_group=();
my %tmp_hash=();


###################
## connecting DB
my $conn = DBI->connect("dbi:Pg:dbname=hpkd_db;host=localhost;port=5433;user=malonso;password='manuel'");
###################

###################
## querying DB 
$query = $conn->prepare("SELECT hpkd_group, hpkd_family, avg(char_length(hpkd_sequence)) ".
                        "FROM hpkd ".
                        "GROUP BY hpkd_group,hpkd_family ".
                        "ORDER BY hpkd_group,hpkd_family")or die $conn->errstr;
$query->execute() or die $conn->errstr;
###################

###################
## preparing the data file for gnuplot
open(DATAFILE,">datafile.dat") or die;

# not that here you must be sure that there are not two PKfamilies with the same name !
while (@row = $query->fetchrow_array()){ 
  $hash_group{$row[1]}=[@row];
}

foreach $group (@PKgroups){
  foreach $family (keys %hash_group){
    if($hash_group{$family}[0] eq $group){
      $tmp_hash{$family}=$hash_group{$family};
      delete $hash_group{$family};
    }
  }
  foreach (sort {$tmp_hash{$b}[2] <=> $tmp_hash{$a}[2]} keys %tmp_hash){ # sort by avg
    $index++;
    printf DATAFILE ("%s\t%s\t%d\t%.2f\n",$tmp_hash{$_}[0],$tmp_hash{$_}[1],$index,$tmp_hash{$_}[2]);# ( group, family, index, avg_seq_lenght)
    $xtics_labels = $xtics_labels."\"$tmp_hash{$_}[1]\" $index,";
  }
  %tmp_hash=();
  $index++; # empty tics
  $xtics_labels = $xtics_labels."\"\" $index,"; #  empty tics
  print DATAFILE "\n\n";
}

chop($xtics_labels);
close(DATAFILE);
###################

###################
## disconnecting DB
$conn->disconnect();
###################

###################
## Creating (from a template) the gnuplot script
##
open(I,"/home/malonso/phd/kinome/scripts/plot_avg_hpkd_lenght_per_family_TEMPLATE.gnuplot") or die; # open gnuplot template file
open(O,">gnuplot_script_file") or die;
while(<I>){
  if($_ =~ /XTICS_LABELS/){$_ =~ s/XTICS_LABELS/$xtics_labels/;}
  elsif($_ =~ /GNUPLOT_DATA_FILE/){$_ =~ s/GNUPLOT_DATA_FILE/datafile.dat/;}
  elsif($_ =~ /GNUPLOT_OUTPUT_FILE/){$_ =~ s/GNUPLOT_OUTPUT_FILE/outputfile/;}
  print O "$_";
}
close(I);
close(O);
###################


###################
#### Executing gnuplot
system("gnuplot gnuplot_script_file");
###################

