#!/usr/bin/env perl
#
# created approx. on 2010-12-13
# modif & improved on 2011-08-18
#
# Identifying [H|Y]RD (and similar) conserved catalytic motifs in HPKD sequences.
# Kinase name, sequence of the identified motif and motif index in
# the sequence of the HPKD are shown (when identified).
#
#
use strict;
use warnings;
use LoadFile;
use Fasta2Hash;

my (%hpkDom_seq, %hpkProt_seq)=();
my %hpkDom_motif=(); ## {hpkDom_name}=[motifseq, motifseq_ctexp, motif_idx_in_hpkDom]
my %hpk_motifs=(); ## {hpkDom_name}=[motifseq, motifseq_ctexp, motif_idx_in_hpkDom, motif_idx_in_hpkProt]

##############################
## Loading sequences
%hpkProt_seq = Fasta2Hash(File2Array("/home/malonso/phd/kinome/hpk/hpkp.fasta"));
%hpkDom_seq = Fasta2Hash(File2Array("/home/malonso/phd/kinome/hpk/hpkd.fasta"));
##############################

##############################
## Searching [H|Y]RD motifs in HPKDoms sequences.
%hpkDom_motif=motif_index_in_hpkDom(\%hpkDom_seq);
##############################

##############################
## Searching [H|Y]RD motifs in HPKProts sequences.
%hpk_motifs=motif_index_in_hpkProt(\%hpkDom_motif, \%hpkDom_seq, \%hpkProt_seq);
print_hpk_motifs(\%hpk_motifs);
##############################


##############################
####### SUBROUTINES ##########
##############################

##############################
## Searching for the motifs in HPKProts sequences.
## Argument:
## 1) reference to a hash with hpkP sequences {hpkname}=>seq
## Returns:
## 1) a hash {hpkDom_name}=[motifseq, motifseq_ctexp, motif_idx_in_hpkDom, motif_idx_in_hpkProt]
##
sub motif_index_in_hpkProt{
  my ($sec_dom_flag, $sec_dom_name, $idx, $idx_Dom, $idx_Prot, $motif_seq);
  my @fields;
  my %return_hash;  ## {hpkDom_name}=[motifseq, motifseq_ctexp, motif_idx_in_hpkDom, motif_idx_in_hpkProt]
  my %Dom_motif = %{$_[0]}; ## {hpkDom_name}=[motifseq, motifseq_ctexp, motif_idx_in_hpkDom]
  my %Dom_seq = %{$_[1]};
  my %Prot_seq = %{$_[2]};
  
  foreach my $name (keys %Dom_motif){
    $sec_dom_flag=0;
    $idx_Dom = $Dom_motif{$name}[2];
    $motif_seq = $Dom_motif{$name}[0];
    
    ## If there is no identifyied motif for the current domain
    ## fill the array with "-" and go to next domain.
    if($Dom_motif{$name}[0] eq "-"){
      $return_hash{$name}=[qw(- - - -)];
      next;
    }
    
    ## If the current is a secondary domain
    ##   1) activate the corresponding flag.
    ##   2) keep only the base name (without ~b).
    if($name =~ /~/){
      $sec_dom_flag++;
      @fields = split("\~",$name);
      $name=$fields[0];
    }
    
    ## Locate motifs in Prot sequences.
    if($sec_dom_flag==0){
      $idx = index($Prot_seq{$name},$Dom_seq{$name});
      $idx_Prot = $idx + $idx_Dom;
      $return_hash{$name}=$Dom_motif{$name};
      push(@{$return_hash{$name}},$idx_Prot);
    }else{
      $sec_dom_name=$name."~b";
      $idx = index($Prot_seq{$name},$Dom_seq{$sec_dom_name});
      $idx_Prot = $idx + $idx_Dom;
      $return_hash{$sec_dom_name}=$Dom_motif{$sec_dom_name};
      push(@{$return_hash{$sec_dom_name}},$idx_Prot);
    }
  }
  return %return_hash;
}
##############################

##############################
## Searching for the motifs in HPKD sequences.
## Argument:
## 1) reference to a hash with hpk sequences {hpkname}=>seq
## Returns:
## 1) a hash {hpkDom_name}=[motifseq, motif_idx_in_hpkDom]
##
sub motif_index_in_hpkDom{
  my %hpkDom_seq = %{$_[0]};
  my %return_hash;
  my ($hpkd,$seq,$motif,$motif_ctexp,$index,$ini_index) = "";
  
  foreach (keys %hpkDom_seq){
    $ini_index=0; $index="-"; $motif="-";
    
    if($hpkDom_seq{$_} =~ /([H|Y]RD)(\w{3})/){ ## Conserved Motif
      ## Iterate while there remains matches for the motif
      ## and the index of the matches in the sequence are < 100.
      while($hpkDom_seq{$_} =~ /([H|Y]RD)(\w{3})/g && $ini_index<100){
        $motif = $1;
        $motif_ctexp = $motif.$2;
        $index = index($hpkDom_seq{$_}, $motif, $ini_index);
        $ini_index = $index+1;
      }
    }elsif($hpkDom_seq{$_} =~ /(H[F|L|G|T|K]D[I|L])(\w{3})/){ ## Conserved Motif Variant
      while($hpkDom_seq{$_} =~ /(H[F|L|G|T|K]D[I|L])(\w{3})/g && $ini_index<100){
        $motif = $1;
        $motif_ctexp = $motif.$2;
        $index = index($hpkDom_seq{$_}, $motif, $ini_index);
        $ini_index = $index+1;
      }
    }elsif($hpkDom_seq{$_} =~ /(HCDL)(\w{3})/){ ## Conserved Motif Variant 
      while($hpkDom_seq{$_} =~ /(HCDL)(\w{3})/g && $ini_index<100){
        $motif = $1;
        $motif_ctexp = $motif.$2;
        $index = index($hpkDom_seq{$_}, $motif, $ini_index);
        $ini_index = $index+1;
      }
    }elsif($hpkDom_seq{$_} =~ /(HRNL)(\w{3})/){ ## Conserved Motif Variant
      while($hpkDom_seq{$_} =~ /(HRNL)(\w{3})/g && $ini_index<100){
        $motif = $1;
        $motif_ctexp = $motif.$2;
        $index = index($hpkDom_seq{$_}, $motif, $ini_index);
        $ini_index = $index+1;
      }
    }elsif($hpkDom_seq{$_} =~ /(HGNV)(\w{3})/){ ## Conserved Motif Variant (Catalytically Inactive)
      while($hpkDom_seq{$_} =~ /(HGNV)(\w{3})/g && $ini_index<100){
        $motif = $1;
        $motif_ctexp = $motif.$2;
        $index = index($hpkDom_seq{$_}, $motif, $ini_index);
        $ini_index = $index+1;
      }
    }elsif($hpkDom_seq{$_} =~ /(HM[L|V]FE)(\w{3})/){ ## Motif for aPKs of PDHK family
    while($hpkDom_seq{$_} =~ /(HM[L|V]FE)(\w{3})/g && $ini_index<=0){
        $motif = $1;
        $motif_ctexp = $motif.$2;
        $index = index($hpkDom_seq{$_}, $motif, $ini_index);
        $ini_index = $index+1;
      }
    }
    $motif=$index="-" if($index ne "-" && $index==-1);
    $return_hash{$_}=[$motif,$motif_ctexp,$index];
  }
  return %return_hash;
}
##############################


##############################
## Printing out the hash
sub print_hpk_motifs{
  my %hash = %{$_[0]};
  my $date=`date \'+%Y-%m-%d_%H.%M\'`;
  chomp($date);
  open(O, ">hpkd_HY-RD_motifs.$date.tab") or die;
  print O "# List of [H|Y]RD (and similar) catalytic motifs in HPK sequences.\n";
  print O "# Kinase domain name, sequences of the identified motif and motif\n";
  print O "# indexes in HPKDom and HPKProt sequences are shown.\n";
  print O "# Script: hpkDom_HY-RD_motifs.pl\n";
  print O "#\n";
  print O "#hpkd_name\tmotif_seq\tmotif_seq_ctexp\tidx_dom\tidx_prot\n";
  foreach (sort keys %hash){
    ## Print existing motifs
    printf O ("%s\n", join("\t", $_, @{$hash{$_}})) if($hash{$_}[0] ne "-");
  }
  foreach (sort keys %hash){
    ## Print non existing motifs
    printf O ("%s\n", join("\t", $_, @{$hash{$_}})) if($hash{$_}[0] eq "-");
  }
  close(O);
}
##############################
