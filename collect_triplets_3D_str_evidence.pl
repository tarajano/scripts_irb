#!/usr/bin/env perl
#
# created on: 22/Feb/2013 at 10:47 by M.Alonso
# 
# Retrieving Structural information (Interactome3D) for PPIs between
#   - Kinases - AS
#   - AS - Substrates
# for the cases of AS that interact with a stat. signif. fraction of the 
# kinase substrates.
# 
# The current script tries to identify in Interactome3D complete 3D structures (3DS)
# homology models (HMD) or domain-domain models (DDM) - in this order -
# for a given PPI. In case a good 3DS is found ( >= 70% Avg Seq. Covg.)
# no additional 3DS, HMD nor DDM are searched for the current PPI; otherwise, 
# the script will try to identify a good HMD ( >= 70% Avg Seq. Covg.) and
# if none is found, then the script will look for DDM.
# Due to the described procedure, for a given PPI more than one instance
# of structural information (3DS, HMD or DDM) could be present in the
# output file. This could be useful when trying to identify different
# interacting regions in the proteins:
#
#, e.g. (P62993 - Q8IZP0):
#     AS-SUB  HMD     P62993  B       57.9    26.3    Q8IZP0  A       42      9.8     2sem.pdb1       2.2     P62993-Q8IZP0-MDL-2sem.pdb1-B-0-A-0.pdb 49.95   18.05
#     AS-SUB  DDM     P62993  SH3_1   A       37.8    19.8    Q8IZP0  SH3_1   B       20.5    8.5     1i07    1.8     P62993-Q8IZP0-MDD-SH3_1-SH3_1-1i07-A-10-55-B-10-55.pdb  29.15   14.15
# 
# 
# The output fields of this script are, in this order:
# 
#   - [ PK-AS | AS-SUB ]: whether the current entry corresponds to a Kinase-AdapScaff or to a AdapScaff-Substrate PPI
#   - [3DS | HMD | DDM  | NO]: whether we count with a: complete 3D structure, an homology model, a domain-domain model or no model for current PPI
#
#   If the entry is 3DS (complete 3D structure)
#     - AC: From Kinase or AS
#     - PDB chain ID
#     - Percent Sequence Identity
#     - Percent Sequence Coverage
#     - AC: From AS or Subs
#     - PDB chain ID
#     - Percent Sequence Identity
#     - Percent Sequence Coverage
#     - PDB file
#     - Resolution of PDB file
#     - Average Percent Sequence Identity
#     - Average Percent Sequence Coverage
#
#   If the entry is HMD (Homology Model)
#     - AC: From Kinase or AS
#     - PDB chain ID
#     - Percent Sequence Identity
#     - Percent Sequence Coverage
#     - AC: From AS or Subs
#     - PDB chain ID
#     - Percent Sequence Identity
#     - Percent Sequence Coverage
#     - PDB file
#     - Resolution of PDB file
#     - Homolgy Modeling PDB file
#     - Average Percent Sequence Identity
#     - Average Percent Sequence Coverage
# 
#   If the entry is DDM (Domain-Domain Model)
#     - AC from Kinase or AS
#     - Interacting Domain
#     - PDB chain ID
#     - Percent Sequence Identity
#     - Percent Sequence Coverage
#     - AC from AS or Subs
#     - Interacting domain
#     - PDB chain ID
#     - Percent Sequence Identity
#     - Percent Sequence Coverage
#     - PDB ID
#     - Resolution of PDB file
#     - Homolgy Modeling PDB file
#     - Average Percent Sequence Identity
#     - Average Percent Sequence Coverage
# 
# 
# Usage:
# As input for this script I'm using the results from the statistical 
# evaluation of AS that interact with a signif. fraction of a kinase
# substrate:
#   - i.e: compute_stat_signif_pks_kas_subs.pl ./compute_stat_signif_pks_kas_subs.tab > collect_triplets_3D_str_evidence_pks_kas_subs.out
# 
#
# 

##############################
### Loading modules

### Installed modules (CPAN, Perl)
use strict;
use warnings;
use Data::Dumper; # print Dumper myDataStruct
#use Statistics::R;
#use List::MoreUtils qw(uniq);

### Modules by MAAT
use LoadFile;
#use ListCompare qw(retrieve_intersection retrieve_union);
use DBServer qw(connect2interactome3D disconnect2interactome3D);
use Interactome3DUtils qw(
                          retrieve_best_3D_model_for_binary_ppi_by_avg_seqs_cov_avg_seqs_ids
                          retrieve_best_3D_structure_for_binary_ppi_by_avg_seqs_cov_avg_seqs_ids
                          retrieve_best_3D_domdom_model_for_binary_ppi_by_avg_seqs_cov_avg_seqs_ids
                          );
#


##############################

##############################
### Variables definition
my $avg_seq_cov_threshold = 70;
my ($infile, $pk, $as);
my (@fields, @infile, @subs, @str_model_data);
##############################


##############################
### Main

### Get input file
unless (defined $ARGV[0] && -e $ARGV[0]){
  print "Please, provide an input file\n";
}else{
  $infile = $ARGV[0];
  @infile = File2Array($infile, 1);
}



### Connect to Interactome3D
my $conn_int3D = connect2interactome3D();

foreach my $line (@infile){
  ### O14757	P31946	4/17	0.0039	0.0273	O15151,P30304,P30305,P30307
  @fields = splittab($line);
  ($pk, $as) = @fields[0..1];
  @subs = splitcomma($fields[-1]);
  
  
  ### Collecting and printing structural data for PK-AS PPI
  @str_model_data = @{collect_ppi_str_data('PK-AS', $pk, $as)};
  foreach my $i (@str_model_data){
    @fields = @{$i};
    printf ("%s\n", jointab(@fields) );
  }
  ### Collecting and printing structural data for AS-SUB PPI
  foreach my $sub (@subs){
    @str_model_data = @{collect_ppi_str_data('AS-SUB', $as, $sub)};
    foreach my $i (@str_model_data){
      @fields = @{$i};
      printf ("%s\n", jointab(@fields) );
    }
  }
  printf ("//\n"); 
}


### Disconnect from Interactome3D
disconnect2interactome3D($conn_int3D);
##############################

##############################
######## SUBROUTINES ######### 
##############################

##############################
### Description:
###   
### Usage:
###   
### Input:
###   
### Output:
###   
sub collect_ppi_str_data{
  my ($ppi_elements, $ac1, $ac2) = ($_[0], $_[1], $_[2]);
  my (@ppi_str_data, @tds, @hmd, @ddm);
  
  ### Querying for 3D structures, homology models and domain-domain models
  ### of the PPI.
  @tds = retrieve_best_3D_structure_for_binary_ppi_by_avg_seqs_cov_avg_seqs_ids($ac1, $ac2);
  @hmd = retrieve_best_3D_model_for_binary_ppi_by_avg_seqs_cov_avg_seqs_ids($ac1, $ac2);
  @ddm = retrieve_best_3D_domdom_model_for_binary_ppi_by_avg_seqs_cov_avg_seqs_ids($ac1, $ac2);
  
  ### Check (and return) if a good 3D structure was found for the PPI.
  ### By good PPI I mean avg_seq_cov >= avg_seq_cov_threshold.
  ### If avg_seq_cov < avg_seq_cov_threshold, save the 3D structure found
  ### and proceed to save homology model and domain-domain model (if any).
  if(0 < scalar @tds && $tds[-1] >= $avg_seq_cov_threshold){
    unshift(@tds, ($ppi_elements,'3DS'));
    push(@ppi_str_data, [@tds]);
    return \@ppi_str_data;
  }elsif(0 < scalar @tds && $tds[-1] < $avg_seq_cov_threshold){
    unshift(@tds, ($ppi_elements,'3DS'));
    push(@ppi_str_data, [@tds]);
  }
  
  ### Check (and return) if a good homology model was found for the PPI.
  ### By good homology model I mean avg_seq_cov >= avg_seq_cov_threshold.
  ### If avg_seq_cov < avg_seq_cov_threshold, save the homology model found
  ### and proceed to save domain-domain model (if any).
  if(0 < scalar @hmd && $hmd[-1] >= $avg_seq_cov_threshold){
    unshift(@hmd, ($ppi_elements,'HMD'));
    push(@ppi_str_data, [@hmd]);
    return \@ppi_str_data;
  }elsif(0 < scalar @hmd && $hmd[-1] < $avg_seq_cov_threshold){
    unshift(@hmd, ($ppi_elements,'HMD'));
    push(@ppi_str_data, [@hmd]);
  }
  
  ### Check (and return) if a domain-domain model was found for the PPI.
  if(0 < scalar @ddm){
    unshift(@ddm, ($ppi_elements,'DDM'));
    push(@ppi_str_data, [@ddm]);
  }
  
  if(0 == scalar @ppi_str_data){
    push(@ppi_str_data, [$ppi_elements, 'NO', $ac1, $ac2]);
  }
  return \@ppi_str_data;
  
}
##############################


