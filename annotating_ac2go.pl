#!/usr/bin/env perl
#
# created on: 31/Aug/2011 by M.Alonso
#
# Parsing sprot_HUMAN_parsed_lines looking for GO terms of 
# query ACs.
#
# Annotating input ACs.
#
# usage: 
#  script.pl queryacs.list
# 

use strict;
use warnings;
use LoadFile;

my $inputfile=$ARGV[0];
my $primAC;
my $proteome_AC2GO_mapping_output_file="hs_uniprot_2011_11_AC2GO.map";


my (@tmp, @fields, @fields2, @secondACs, @GOids, @VarSplicACs, @unmapped_ACs);

my (%Query_ACs, %tmp);

## Storing data from sprot_HUMAN_parsed_lines file.
## These data will be used for the parsing.
## {AC}=[[secAC,secAC], [varsplicAC,varsplicAC], [GOid, GOid]]
my %sprot_HUMAN_parsed_lines;

## Kepping a GOids, NameSpaces and Names mappings.
## {goid}=[namespace, name]
my %gene_ontology;

## Keeping the GOids assignments of query ACs
my %ac2go;


##############################
## Loading target ACs
## Loading prev. defined human proteome
#my $proteome_acs_list="/aloy/home/malonso/phd_proj_dbs/uniprot/uniprot_2011_11/hs_proteome_uniprot_2011_11_ACs.list"; ## One AC per line
my $proteome_acs_list = $ARGV[0];## One AC per line

for(File2Array($proteome_acs_list)){
  @fields = splittab($_);
  $Query_ACs{$fields[0]}=1 
}
printf("ACs to map: %d\n", scalar(keys %Query_ACs));
##############################

###############################
## Loading subcellular location GOs from sprot_HUMAN_parsed_lines.
## Constructing a datastructure for mapping ACs to GOs.
## 
print "Loading GO terms annotations\n";
my $proteome_parsed_lines_file="/aloy/home/malonso/phd_proj_dbs/uniprot/uniprot_2011_11/sprot_HUMAN_parsed_lines";
foreach(File2Array($proteome_parsed_lines_file)){
  @GOids=();
  @VarSplicACs=();
  
  @fields = split('\|',$_);
  
  ## Primary AC
  $primAC = $fields[1];
  
  ## Parsing and storing secondary ACs
  @secondACs = split(";",$fields[2]);
  
  ## Parsing and storing VARSPLICs ACs
  @tmp = split(";",$fields[17]);
  foreach(@tmp){
    my @fields2 = split(",",$_);
    push(@VarSplicACs,$fields2[0]);
  }
  
  ## Retrieving all GOids of current AC.
  ## GOids will have to be mapped later to 
  ## their corresponding names.
  @tmp = @fields[21..23];
  @GOids = parsing_GOids(\@tmp);

  $sprot_HUMAN_parsed_lines{$primAC}=[[@secondACs],[@VarSplicACs],[@GOids]];
} ## print "$_:\n@{$sprot_HUMAN_parsed_lines{$_}[0]}\n@{$sprot_HUMAN_parsed_lines{$_}[1]}\n@{$sprot_HUMAN_parsed_lines{$_}[2]}\n\n" foreach(keys %sprot_HUMAN_parsed_lines);
###############################

################################
## Parsing and loading GO ids, names and
## namespaces, etc from gene_ontology_ext.obo file.
print "Loading GO ids, names and namespaces from gene_ontology_ext.obo file\n";
%gene_ontology = load_gene_ontology("/aloy/home/malonso/phd_proj_dbs/GO/gene_ontology_ext.obo");
################################

################################
## Conducting the mappings
print "Mapping is ongoing ...\n";
my ($hashref ,$arrayref) = annotating_AC2GO(\%Query_ACs, \%sprot_HUMAN_parsed_lines, \%gene_ontology);
%ac2go = %{$hashref};
@unmapped_ACs = @{$arrayref};
print "Mapping done\n";
printf ("  %d ACs without GO annotation\n", scalar(@unmapped_ACs));
################################

#################################
## Printing AC 2 GO mappings
print("Saving to files\n");
open(O, ">tmp");
foreach my $i (keys %ac2go){
  foreach (@{$ac2go{$i}}){
    print O "$i\t$_\n";
  }
}
print O "$_\tNO_GO_TERMS_AVAIL\n" foreach (@unmapped_ACs);
close(O);

system("sort tmp > $proteome_AC2GO_mapping_output_file");
unlink("tmp");
print("Done!\n");
#################################


################################
######### SUBROUTINES ##########
################################

################################
## Parsing and retrieving GO ids
## in GO annotation lines of
## sprot_HUMAN_parsed_lines file.
## INPUT: 
##  
sub parsing_GOids{
  my @lines_to_parse=@{$_[0]};
  my (@tmp, @tmp2, @goids);
  for(@lines_to_parse){
    push(@tmp, split(";",$_));
  }
  for(@tmp){
    @tmp2 = split("-",$_);
    push(@goids, $tmp2[0]);
  }
  return @goids;
}
################################

################################
## Parsing and loading GO ids, names and
## namespaces from gene_ontology_ext.obo file.
sub load_gene_ontology{
  ## Provide path to file gene_ontology_ext.obo.
  my @file=File2Array($_[0]);
  my ($GOid,$name,$namespace);
  my @fields;
  my %goid_name; ## {goid}=[namespace,name]
  
  for(my $i=0; $i<=$#file; $i++){
    if($file[$i] eq "[Term]"){
      $namespace="";
      if($file[$i+3] eq "namespace: biological_process"){$namespace="BP";}
      elsif($file[$i+3] eq "namespace: molecular_function"){$namespace="MF";}
      elsif($file[$i+3] eq "namespace: cellular_component"){$namespace="CC";}
      
      if($namespace ne ""){
        @fields=split(" ",$file[$i+1]);
        $GOid=$fields[-1];
        @fields=split("name: ",$file[$i+2]);
        $name=$fields[1];
        $goid_name{$GOid}=[$namespace,$name];
      }
    }
  }
  ## {goid}=[namespace,name]
  return %goid_name;
}
################################

################################
## Assigning GOids to query ACs only if GOids
## exist in the mapping hash of cellular_components.
## 
## RETURNS:
## {ac}=(goid, goid)
#sub only_cellular_component_gos{
  #my @gos=@{$_[0]};
  #my $k=$_[1];
  #my %go2name=%{$_[2]};
  #my %hash;
  #foreach my $go (@gos){
    #push(@{$hash{$k}},$go) if(exists $go2name{$go});
  #}
  #return %hash;
#}
################################

################################
##
##
sub annotating_AC2GO{
  my %queryACs = %{$_[0]};
  my %sprot_HUMAN_parsed_lines = %{$_[1]};
  my %goid2name = %{$_[2]};
  
  my ($tmp, $primAC, $k1, $k2, $k3);
  my (@unmapped, @fields, @tmp);
  my %query_VARSPLICs; ## {canonicalAC}=varsplicAC
  my %tmp;
  my %query_AC2GO; ## {AC}="namespace goid name"
  
  ###############################
  ## Assigning GO to query ACs.
  
  foreach $k1 (keys %queryACs){
    ## Checking if query AC exists among
    ## primary ACs of sprot_HUMAN_parsed_lines.
    if(exists $sprot_HUMAN_parsed_lines{$k1}){
      ## Assigning GOids to query ACs and attempting to map the GOid
      ## to namespace and name as of gene_ontology_ext.obo file.
      foreach my $go (@{$sprot_HUMAN_parsed_lines{$k1}[-1]}){
        if(exists $gene_ontology{$go}) {
          push(@{$query_AC2GO{$k1}},join("\t",$gene_ontology{$go}[0],$go,$gene_ontology{$go}[1]));
        }
      }
      $query_AC2GO{$k1}=["NO_GO_TERMS_AVAIL"] unless (exists $query_AC2GO{$k1});
      delete $queryACs{$k1};
    }
  }
  @unmapped = keys %queryACs;
  
  ## If unmapped is an empty list, return AC2GO mappings
  return (\%query_AC2GO, \@unmapped) if(0==scalar(@unmapped));
  
  ## Checking if query AC exists among secondary ACs 
  ## or VARSPLICs of sprot_HUMAN_parsed_lines.
  @unmapped = keys %queryACs;
  if(0<scalar(@unmapped)){
    foreach $k1 (keys %sprot_HUMAN_parsed_lines){
      ## Searching in secondary ACs
      foreach $k2 (@{$sprot_HUMAN_parsed_lines{$k1}[0]}){
        if(exists $queryACs{$k2}){
          foreach my $go (@{$sprot_HUMAN_parsed_lines{$k1}[-1]}){
            if(exists $gene_ontology{$go}){
              push(@{$query_AC2GO{$k2}},join("\t",$gene_ontology{$go}[0],$go,$gene_ontology{$go}[1]));
            }
          }
          $query_AC2GO{$k2}=["NO_GO_TERMS_AVAIL"] unless (exists $query_AC2GO{$k2});
          delete $queryACs{$k2};
        }
      }
      @unmapped = keys %queryACs; 
      last if(0==@unmapped);
      
      ## Searching in VARSPLICs
      foreach $k2 (@{$sprot_HUMAN_parsed_lines{$k1}[1]}){
        if(exists $queryACs{$k2}){
          foreach my $go (@{$sprot_HUMAN_parsed_lines{$k1}[-1]}){
            if(exists $gene_ontology{$go}){
              push(@{$query_AC2GO{$k2}},join("\t",$gene_ontology{$go}[0],$go,$gene_ontology{$go}[1]));
            }
          }
          $query_AC2GO{$k2}=["NO_GO_TERMS_AVAIL"] unless (exists $query_AC2GO{$k2});
          delete $queryACs{$k2};
        }
      }
      @unmapped = keys %queryACs;
      last if(0==scalar(@unmapped));
    }
  }
  
  ## Returning mapped and unmapped
  return (\%query_AC2GO, \@unmapped) if(0==scalar(@unmapped));
  
  ## If query ACs is a VARSPLIC AC without a match in sprot_HUMAN_parsed_lines,
  ## I will try to assign it by using its corresponding canonical AC.
  @unmapped = keys %queryACs;
  if(0<@unmapped){
    foreach $k1 (keys %queryACs){
      @fields = split("-", $k1);
      ## If current query AC is a VARSPLIC create a mapping
      ## canonical <-> varsplic
      $query_VARSPLICs{$fields[0]}=$k1 if(1<@fields); ## {canonicalAC}=varsplicAC
    }
  }
  @tmp = keys %query_VARSPLICs;
  if(0<scalar(@tmp)){
    foreach $k1 (keys %query_VARSPLICs){
      if(exists $sprot_HUMAN_parsed_lines{$k1}){
        foreach my $go (@{$sprot_HUMAN_parsed_lines{$k1}[-1]}){
          if(exists $gene_ontology{$go}){
            push(@{$query_AC2GO{$query_VARSPLICs{$k1}}},join("\t",$gene_ontology{$go}[0],$go,$gene_ontology{$go}[1]));
          }
        }
        $query_AC2GO{$query_VARSPLICs{$k1}}=["NO_GO_TERMS_AVAIL"] unless (exists $query_AC2GO{$query_VARSPLICs{$k1}});
        delete $queryACs{$query_VARSPLICs{$k1}};
      }
    }
  }
  ###############################
  
  ## Returning mapped and unmapped
  @unmapped = keys %queryACs;
  return (\%query_AC2GO, \@unmapped);
}

################################

