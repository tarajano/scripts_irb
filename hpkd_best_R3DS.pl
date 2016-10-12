#!/usr/bin/env perl
#
# created on: 24/Jan/2011 by M.Alonso
#
# Retrieving the best R3DS for each HPKD
#
#  FOR PLOTTING BEST R3DS VS BEST R3DS FOR EACH HPKDs
#  UNFINISHED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
#
use DBI;
use strict;
use warnings;


## array that will contain the best R3DS PDB file for each hpkd
my @hpkd_best_r3ds;


######################
## File containing the paths to all summary files
my @summary_files;
open(SUM,"/aloy/scratch/malonso/struct_alignments/daliLite/paths_to_summaries.txt");
@summary_files=<SUM>;
chomp(@summary_files);
@summary_files = sort (@summary_files);
close(SUM);
######################





######################
## Querying hpkd_db DB 
## connecting DB
my $conn = DBI->connect("dbi:Pg:dbname=hpkd_db;host=localhost;port=5433;user=malonso;password='manuel'")or die DBI->errstr;

## Retrieving HPKDs names for which there are R3DS available
my $hpkds = $conn->prepare("SELECT distinct(hpkd_name) from public.hpkd_templates_realseq where need_to_model='no'")or die $conn->errstr;
$hpkds->execute() or die $conn->errstr;

## Preparing query for fetching best R3DS.
## Retrieving the R3DSs with higher QC and Resolution.
my $r3ds = $conn->prepare("SELECT template_file ".
                          "FROM public.hpkd_templates_realseq ".
                          "WHERE need_to_model='no' AND hpkd_name = ? ".
                          "ORDER BY qc DESC, pdb_res ASC ".
                          "LIMIT 1 ")or die $conn->errstr;

## Executing query for fetching best R3DS
while(my @hpkds = $hpkds->fetchrow_array()){
  $r3ds->bind_param(1, "$hpkds[0]");  # placeholders are numbered from 1
  $r3ds->execute() or die $conn->errstr;
  
  while(my @r3ds = $r3ds->fetchrow_array()){
    # $r3ds[0] = template_file
    my ($r3ds_pdb,$t) = split(".pdb",$r3ds[0]);
    push(@hpkd_best_r3ds,$r3ds_pdb)
  }
}#print "$_\n" for(@hpkd_best_r3ds);

$hpkds->finish();
$r3ds->finish();
## disconnecting DB
$conn->disconnect();
######
######################


######################
@hpkd_best_r3ds = sort (@hpkd_best_r3ds);
for(my $i=0; $i<$#hpkd_best_r3ds;$i++){
  for(my $ii=($i+1); $ii<=$#hpkd_best_r3ds;$ii++){
    #print "$hpkd_best_r3ds[$i]\t$hpkd_best_r3ds[$ii]\n";
    
    ## Processing DALI Summary Files
    print "$hpkd_best_r3ds[$i]\t$hpkd_best_r3ds[$ii]\n";
    my $sumfile = locating_summary_file($hpkd_best_r3ds[$i],$hpkd_best_r3ds[$ii]);
    
    #parse_summary_create_dali_datafile($sumfile,$hpkd_best_r3ds[$i],$hpkd_best_r3ds[$ii]);
    
    ## Processing RAPIDO XML Files
    
  }
} 
######################


#############################
## locating summary file of current hpkd pair
sub locating_summary_file{
  my @fields;
  my $sumfile;
  my ($hpkd1, $hpkd2) = ($_[0],$_[1]);
  for(my $i=0; $i<=$#summary_files; $i++){
    @fields = split("/",$summary_files[$i]);
    @fields = split("_vs_",$fields[-2]);
    #print "$fields[0]\t$fields[1]\n";
    ### locating the proper summary file and deleting its name from the array once is found
    if(($fields[0] eq $hpkd1 && $fields[1] eq $hpkd2) || ($fields[0] eq $hpkd2 && $fields[1] eq $hpkd1)){
      print "$summary_files[$i]\n";
      delete $summary_files[$i];
      return $sumfile;
      last;
    }
  }
}
#############################


#############################
## Parsing  files & creating GnuPlot Data file
##
sub parse_summary_create_dali_datafile{
  # pase summary files and fill hash {str1}{str2}=rmsd
  my $summary_file = $_[0];
  my ($hpkd1,$hpkd2) = ($_[1],$_[2]);
  my @fields;
  my $rmsd;
  my $summary_file_line=1;
  
  open(DATAFILE,">>/aloy/scratch/malonso/struct_alignments/daliLite/hpkd_best_R3DS_rmsd.tab") or die;
  
  ## retrieving rmsd values
  open(I,$summary_file) or die;
  while(<I>){
    ## grabbing the rmsd value in the 3rd line of summary file
    if($summary_file_line == 3){
      chomp();  
      @fields = split(' +',$_);
      if($#fields > 0 && defined $fields[3] && defined $fields[4] && $fields[3]>=2){
        ## Cheking if Z-value & RMSD values exists in summary.txt file && 
        ## cheking if Z-value >= 2 ("Similarities with a Z-score lower than 2 are spurious", ekhidna.biocenter.helsinki.fi/dali_server)
        $rmsd = $fields[4];
      }else{
        # For structures that Dali fails to compute the rmsd RAPIDO assigns rigid rmsd > 10 Angstroms,
        # following this I assign the arbitrary value of 15 Angstrom of RMSD for those structures pairs that Dali fails to compute RMSD.
        $rmsd = 15;
      }
      last;  
    }else{
      $summary_file_line++;
    }
  }
  close(I);
  print DATAFILE "$hpkd1\t$hpkd2\t$rmsd\n";
  close(DATAFILE);
}
#############################












