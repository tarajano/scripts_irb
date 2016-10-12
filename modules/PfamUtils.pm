# created on: 24/01/2012 by M.Alonso
#
# USAGE:
#   PERL5LIB env variable:
#    update PERL5LIB variable in .bashrc
#    export PERL5LIB=${PERL5LIB}:/home/malonso/phd/kinome/scripts/modules/
#
# CALLING MODULE
#   use PfamUtils;
#

use strict;
use warnings;
use LoadFile;

require Exporter;
package PfamUtils;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(
                      pfamdom2clan
                      loading_pfamclans_data
                      load_uniprotAC2Pfam_assignments
                      retrieve_unique_domains_in_protein_set
                      );    # Symbols to be exported by default
#


##############################
### Description:
###   Given an array of Uniprot ACs it will return an array with 
###   the list of unique Pfam domains that are present in the input set.
###   
### Usage:
###   retrieve_unique_domains_in_protein_set( \@uniprotACs )
###   
###   
### Input:
###   
### Output:
###   
###  
###  
sub retrieve_unique_domains_in_protein_set{
  use List::MoreUtils qw(uniq);
  
  my ($domain);
  my (@proteins, @tmp, @unique_domains);
  my (%uniprot2pfam);
  
  ### Loading list of query proteins
  @proteins = uniq @{$_[0]};
  
  ### Loading pfam assignments
  #print "Loading Pfam assignments\n";
  %uniprot2pfam = %{ PfamUtils::load_uniprotAC2Pfam_assignments("/aloy/home/malonso/phd_proj_dbs/uniprot/uniprot_2011_11/ac2pfam/merged_pfamscan_out.sort.SeqStart.tab") };
  
  foreach my $prot (@proteins){
    
    ### Notify and skip unless the current proteins exists in the uniprot2pfam
    ### assignment file.
    unless (exists $uniprot2pfam{$prot}){
      print "$prot does not exists in Uniprot AC to Pfam assignment file\n";
      next;
    }
    ### Skip if no Pfam domain is assigned to current protein
    unless (defined @{$uniprot2pfam{$prot}} ){
      print "$prot does have Pfam any domains assignment\n";
      next;
    }
    
    foreach my $entry ( @{$uniprot2pfam{$prot}} ){
      ### Grab the domain
      push(@tmp, ${$entry}[0]);
    }
  }
  
  ### Make domains unique
  @unique_domains = sort {$a cmp $b} uniq @tmp;
  
  return \@unique_domains;
}
##############################

##############################
### Loads to a hash of arrays a pre-computed Pfam domain assignments file
### 
### Usage:
###   %h = %{ load_uniprotAC2Pfam_assignments("/path/to/file/with/ac2pfamassignemtns") }
### 
### Input:
###   - File with Uniprot AC to Pfam assignments
###     - Format:
###       O14745  EBP50_C-term    9.5e-25 ?       318     358     PF09007.4
###       O14745  PDZ     2.2e-13 ?       16      91      PF00595.17
###       O14745  PDZ     3.4e-14 ?       154     231     PF00595.17
### 
### Returns:
###  Hash of arrays with UniprotAC to Pfam assignment:
###   {AC}=[ [EBP50_C-term ... ], [PDZ ...], [PDZ ...] ]
###  
###  
###  
sub load_uniprotAC2Pfam_assignments{
  my $infile = shift;
  my @fields;
  my %uniprotAC2Pfam;

  foreach(LoadFile::File2Array($infile)){
    @fields = LoadFile::splittab($_);
    
    ### Dealing with ACs witout Pfam assignments
    if(1 < scalar @fields){ push(@{$uniprotAC2Pfam{$fields[0]}}, [@fields[1..$#fields]]); }
    else{ $uniprotAC2Pfam{$fields[0]}=(); }
    
  }
  return \%uniprotAC2Pfam;
}
##############################

##############################
## Parsing Pfam-C file which contains
## information of Pfam clans (descriptions, members, etc)
## 
## Argument:
## Full path to Pfam-Cfile (e.g. /aloy/data/dbs/pfam/Pfam-C)
## 
## Returns:
## A reference to a hash:
## {clanAC}=[clanID,clanDE,[membersPfamID]]
##
sub loading_pfamclans_data{
  my $pfam_c_file_path = $_[0];
  my ($AC, $ID, $DE, $MB);
  my $flag=0;
  my (@fields, @MB);
  my %returnhash; ##{clanAC}=[clanID,clanDE,[clan members]]
  
  ## Loading Pfam-Clans file
  foreach my $line (LoadFile::File2Array($pfam_c_file_path)){
    @fields = split("   ", $line);
    
    if($fields[0] eq "AC"){
      $AC=$fields[1];
      next if ($flag == 0);
    }elsif($fields[0] eq "ID"){
      $ID=$fields[1];
    }elsif($fields[0] eq "DE"){
      $DE=$fields[1];
    }elsif($fields[0] eq "MB"){
      chop($fields[1]);
      push(@MB, $fields[1])
    }elsif($fields[0] eq "//"){
      $returnhash{$AC}=[$ID, $DE,[@MB]];
      @MB=();
      $ID=$DE="";
    }
    $flag++;
  }
  return \%returnhash;
}
##############################

##############################
sub pfamdom2clan{
  my %hash = %{$_[0]}; ## {clanAC}=[clanID,clanDE,[membersPfamID]]
  my %return_hash; ## {pfamdomAC}=pfamclanAC
  my @members;
  
  foreach my $clan (keys %hash){
    @members = @{$hash{$clan}[2]};
    foreach my $pfamid ( @members ){
      $return_hash{$pfamid }=$clan;
    }
  }
  return \%return_hash;
}
##############################



1;
