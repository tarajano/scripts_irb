#!/usr/bin/env perl
#
# performing AC -> UniRef100 mapping 
#
# input: single AC OR file with a list of ACs
# output: input.mapping
#
# ./uniref-mapping.pl AC.list 
#

use strict;
use warnings;
use DBI;
use List::MoreUtils qw(uniq);

my $uniprotac;
my @mappingpairs;

# Die if no arguments are provided
die "need arguments!!\n" unless ($ARGV[0]); 

##############################
## connecto to uniprotkb_db database
## MAKE SURE TO USE THE CORRECT RELEASE OF UNIREF, ie.
## THE ONE CORRESPONDING TO THE UNIPROT VERSION YOU ARE WORKING WITH
##
my $conn = DBI->connect("dbi:Pg:dbname=uniprotkb_2010_09; host=pac-node3; port=5432 ".
                      "options='';tty=''", "uniprot_user", "uniprot");
##############################

##############################
## define output file
my $outfile=$ARGV[0].".mapped";
## if output file currently exists..deleted
#unlink($outfile) if(-e $outfile);
##############################


##############################
## take arguments (file with a list of ACs OR a single AC)
if(-e $ARGV[0]){
  # If the argument to the script IS a file with UniprotACs:
  # read file line by line and query the DB for each AC
  open(F,$ARGV[0]) or die;
  my @infile=<F>;
  close(F);
  chomp(@infile);
  # make sure there are no repeated ACs
  @infile = uniq(map(uc($_),@infile));
  
  foreach $uniprotac (@infile){UNIREF_MAP($uniprotac);}
}else{
  # if the argument to the script IS a single UniProtAC:
  #  search in DB for this AC
  $uniprotac = $ARGV[0];
  chomp($uniprotac);
  UNIREF_MAP($uniprotac);
}
##############################


##############################
## mapping function
##
sub UNIREF_MAP{
  my @row="";
  my $queryAC = $_[0];
  chomp($queryAC);
  
  ##########
  my $query = $conn->prepare(
  "SELECT uniref100_uniprot_ac, uniprot_ac ".
  "FROM  public.uniprotkb_uniref100 ".
  "WHERE uniprot_ac='$queryAC' ");
  $query->execute();
  
  if(@row = $query->fetchrow_array()){
    my $pair = join(" ", @row);
    push(@mappingpairs,$pair);
    print "$pair\n";
  }else{
    push(@mappingpairs,"$queryAC $queryAC");
    print "$queryAC $queryAC\n";
  }
  undef($query);
  ##########
}
##############################

$conn->disconnect();
$conn = undef;

##############################
## Considering only mappings to canonical sequences
## Any mapping to an isoform will be considered as the mapping
## to the corresponding canonical sequence.
## e.g. P17706-2 A8K3N4 will be considered as: P17706 A8K3N4
##
my @unirefs;

foreach(@mappingpairs){
  chomp;
  my ($uniref, $ac) = split(" ", $_);
  $uniref =~ s/-\d+//;
  push(@unirefs, $uniref);
}

# make sure there are no repeated ACs
@unirefs = uniq(map(uc($_),@unirefs));

## printing out the uniref100 ACs
#open(OUT,">$outfile") or die;
#print OUT "$_\n" foreach(@unirefs);
#close(OUT);

##############################

















