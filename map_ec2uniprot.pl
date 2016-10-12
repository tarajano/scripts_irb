#!/usr/bin/env perl
#
# created on: 10/Mar/2011 by M.Alonso
#
# Mapping ECs to Uniprot ACs or IDs
# Mapping file: http://kr.expasy.org/ftp/databases/enzyme/enzyme.dat (Mar/2011)
#
# Given the file above and a list of (enzymes) uniprot ACs or IDs, retrive their corresponding EC.
# This is useful for classifying the HPKs into Y, S/T, DualSpecificity or CatInactive PKs
# 
# INPUT:
#   enzyme.dat
#   mapping_uniprotID_manning-name_UniprotAC.tab
# OUTPUT:
#   
# 
use strict;
use warnings;

my @fields;
my (@ec_file,@hpks_file);
my ($label,$ec,$tmp,$line);
my (%ec2de, %ec2uniprotAC, %ec2uniprotID, %hpk_unipidac);


##################
## Open & Load query uniprot acs or uniprot ids
# AAK1_HUMAN  AAK1  Q2M2I8
open(HPK,"/home/malonso/phd/kinome/hpk/mapping_uniprotID_manning-name_UniprotAC.tab") or die;
@hpks_file = <HPK>;
chomp(@hpks_file);
close(HPK);
## Storing {unipID}=[HPKname,unipAC]
foreach(@hpks_file){
  @fields = split('\t+',$_);
  $hpk_unipidac{$fields[0]}=[$fields[1],$fields[2]] if($fields[0] ne "*"); # taking only mapped entries
}
##################


##################
## Open & Load EC file
open(EC,"enzyme.dat") or die;
@ec_file = <EC>;
chomp(@ec_file);
close(EC);

## Storing data from enzyme.dat file
for($line=0;$line<=$#ec_file;$line++){
  
  if($ec_file[$line] =~ /^ID\s+/){
    ($label,$ec) = split('\s+',$ec_file[$line]);
    $ec2de{$ec}=""; # Store EC code
    if($ec_file[($line+1)] =~ /^DE\s+(.+$)/){
      $ec2de{$ec}=$ec2de{$ec}." DE: ".$1; $line++; # store DEscription
    }
    if($ec_file[($line+1)] =~ /^AN\s+(.+$)/){
      $ec2de{$ec}=$ec2de{$ec}." AN: ".$1; $line++; # store AlternativeName
    }
  }
  
  if($ec_file[$line] =~ /^DR\s+(.+$)/){
    #print "$ec\t$ec2de{$ec}\n";
    $tmp = $1;
    $tmp =~ s/\s+//g;
    @fields = split(";",$tmp); #AC,ID;AC,ID;AC,ID;
    #print "@fields\n";
    foreach my $acid (@fields){
      my ($uniprotAC,$uniprotID) = split(",",$acid); #AC,ID
      #print "$uniprotAC $uniprotID\t";
      push(@{$ec2uniprotAC{$ec}},$uniprotAC); # store {EC}=[uniprotACs]
      push(@{$ec2uniprotID{$ec}},$uniprotID); # store {EC}=[uniprotIDs]
    }
    #print "\n";
  }
}
##################



##################
## Performing the mapping AC|ID to EC
foreach my $unipid (keys %hpk_unipidac){ # {unipid}=[name,ac]
  my $flag=0;
  foreach my $ec (keys %ec2uniprotID){ # {ec}=[ids]
    foreach my $id (@{$ec2uniprotID{$ec}}){
      if($id eq $unipid){
        printf("%s\n",join("\t",$unipid,$hpk_unipidac{$unipid}[0],$hpk_unipidac{$unipid}[1],$ec,$ec2de{$ec}));
        $flag++; last;
      }
    }
  }
  delete $hpk_unipidac{$unipid} if($flag>0);
}

### Printing out the unmapped entries
my @unmapped = keys %hpk_unipidac;
if (@unmapped > 0){
  print "-- UNMAPPED --\n-- UNMAPPED --\n";
  foreach (keys %hpk_unipidac){
    printf("%s\n",join("\t",$_,$hpk_unipidac{$_}[0],$hpk_unipidac{$_}[1]));
  }
}
#################


##################
### Printing out EC, DE, AN, AC, ID data
#foreach (sort {$a cmp $b} keys %ec2de){
  #print "$_\t$ec2de{$_}\n";
  #print ("@{$ec2uniprotAC{$_}}\n") if (exists $ec2uniprotAC{$_});
  #print ("@{$ec2uniprotID{$_}}\n") if (exists $ec2uniprotID{$_});
#}
##################









