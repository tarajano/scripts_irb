#!/usr/bin/env perl
#
# retrieving the average percent of sequence identity among proteins in all families 
#
# ./ script 
#  output 
#
use strict;
use warnings;
use DBI;

my $index=0;
my $fasta_file_name;
my ($fam_query,$seq_query);
my ($pkgroup,$pkfam,$pkname,$pkclassif,$pkseq,$xtics_labels);

my (@fams,@pkseqs);
my @PKgroups=("AGC","CAMK","CK1","CMGC","Other","RGC","STE","TK","TKL","Atypical");

my %pkfam_pkgroup=(); # {family}=group
my %pkfam_avg_seq_sim=();


###################
## connecting DB
my $conn = DBI->connect("dbi:Pg:dbname=hpkd_db;host=localhost;port=5433;user=malonso;password='manuel'");
###################

###################
## collecting proteins' sequences of each family {family}=[p1, p2, p3]
#$fam_query = $conn->prepare("SELECT distinct(hpkd_family) FROM hpkd")or die $conn->errstr;
$fam_query = $conn->prepare("SELECT distinct(hpkd_group,hpkd_family) from hpkd")or die $conn->errstr;
$fam_query->execute() or die $conn->errstr;

while (@fams = $fam_query->fetchrow_array()){
  $fams[0] =~ /\((\S+),(\S+)\)/;
  $pkfam_pkgroup{$2}=[$1];
  $pkfam=$2;
  $fasta_file_name = $pkfam.".fasta";
  open(FASTA,">$fasta_file_name");
  $seq_query = $conn->prepare("SELECT  hpkd_group, hpkd_family, hpkd_name, hpkd_sequence FROM hpkd WHERE hpkd_family='$pkfam' ")or die $conn->errstr;
  $seq_query->execute() or die $conn->errstr;
 
  while (@pkseqs = $seq_query->fetchrow_array()){
    next if ($pkseqs[3] eq "");
    $pkclassif = join("_",@pkseqs[0..2]);
    $pkseq=$pkseqs[3];
    print FASTA ">$pkclassif\n$pkseq\n";
  }
  close(FASTA);
}
###################

###################
## disconnecting DB
$conn->disconnect();
###################

my @fastafiles = <*.fasta>;

####################
## running T_COFFEE
foreach my $file (@fastafiles){
  $file =~ /(\S+)\.fasta/;
  $pkfam=$1;
  unless (-s $file){ # if the file is empty (no sequence. Atypical family)
    push(@{$pkfam_pkgroup{$pkfam}},0);
    next;
  }
  # uncomment only if you need to recalculate the averages of seq id.
  #system("t_coffee $file ; t_coffee -other_pg seq_reformat -in $pkfam.aln -output sim > $pkfam.sim");
}

## Processing T_COFFEE similarity files
my @simfiles = <*.sim>;

foreach my $file (@simfiles){
  $file =~ /(\S+)\.sim/;
  $pkfam=$1;
  unless (-s $file){ # if the file is empty (pkfam composed of only one protein, assign sim=100)
    push(@{$pkfam_pkgroup{$pkfam}},100);
    next;
  }
  my $tmp = `tail -n1 $file`;   # read the last line of the .sim file. 
  my @tmp = split('\s+',$tmp);  #
  push(@{$pkfam_pkgroup{$pkfam}},$tmp[3]);
}
####################


####################
my %tmp=();
open(DAT,">data.dat");
foreach $pkgroup (@PKgroups){
  foreach $pkfam (keys %pkfam_pkgroup){
    if($pkfam_pkgroup{$pkfam}[0] eq $pkgroup){
      #print "$pkgroup\t$pkfam\t";
      #print "$pkfam_pkgroup{$pkfam}[1]\n";
      $tmp{$pkfam}=$pkfam_pkgroup{$pkfam};
      delete $pkfam_pkgroup{$pkfam};
    }
  }
  foreach (sort {$tmp{$b}[1] <=> $tmp{$a}[1]} keys %tmp){
    $index++;
    print DAT "$tmp{$_}[0]\t$_\t$index\t$tmp{$_}[1]\n";
    $xtics_labels = $xtics_labels."\"$_\" $index,";
  }
  %tmp=();
  $index++;
  $xtics_labels = $xtics_labels."\"\" $index,"; #  empty tics
  print DAT "\n\n";
}
chop($xtics_labels);
close(DAT);
####################

###################
## Creating (from a template) the gnuplot script
##
open(I,"/home/malonso/phd/kinome/scripts/plot_pkfam_avg_percent_seq_id_TEMPLATE.gnuplot") or die; # open gnuplot template file
open(O,">script.gnuplot") or die;
while(<I>){
  if($_ =~ /XTICS_LABELS/){$_ =~ s/XTICS_LABELS/$xtics_labels/;}
  elsif($_ =~ /GNUPLOT_DATA_FILE/){$_ =~ s/GNUPLOT_DATA_FILE/data.dat/;}
  elsif($_ =~ /GNUPLOT_OUTPUT_FILE/){$_ =~ s/GNUPLOT_OUTPUT_FILE//;}
  print O "$_";
}
close(I);
close(O);
###################


###################
#### Executing gnuplot
system("gnuplot script.gnuplot");
###################









