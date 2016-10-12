#!/usr/bin/perl
#
#
# ./parseBlastOutput_mapScop.pl blastout_files.list
#
#
#I used this script for:
  #parsing Blast output files
  #generating a file with the merged results of the homolgs found in blast
  #generating a file with the best homolog found in Scop for each of the HPPD
  #Adding classif and sunid from scop to best results file
#
# input files: blastout.list (paths to every blast output file)
# output files: blast.merged, blast.bestresults.scop
# 

use strict;
use Bio::SearchIO;
use Bio::Search::HSP::BlastHSP;
#use Bio::Search::HSP::GenericHSP;

#
my $OutFile;  # variable for holding the name of output the output file
my %BlastReportHash=(
      "QueryAC"=> , "SubjectAC"=> ,"QueryLength"=> ,"SubjectLength"=> ,
      "\%_SeqID"=> ,"ConservRes"=> ,"E-value"=> ,"Score"=> ,
      "\%_QuerySeqCoverage"=> ,"\%_SubjSeqCoverage"=> ,"HSP-QueryLength"=> ,"HSP-SubjectLength"=> ,
      "HSP-TotalLength"=> ,"Query_start"=> ,"Query_end"=> ,"Subj_start"=> ,"Subj_end"=>
      );
#


################
print "Parsing blast output files\n";

open (INFILE, $ARGV[0]) or die;   ################
my @bastreportfile_list=<INFILE>; # reading-in from the file containing the fullpaths to the blast report files
chomp @bastreportfile_list;       #
close (INFILE);                   ################

foreach my $blastreportfile(@bastreportfile_list){
  $blastreportfile =~ /blast_scop_results\/(.+)\.fasta\./;   # parsing and extracting a base filename for later output
  $OutFile = "$1".".blast.report";
  
  if(-e $OutFile){    ############
    unlink($OutFile);   # deleting the next output file in case it already exists
  }                   ############  
  
  ParseBlastOutputFile($blastreportfile);
}
################


################
sub ParseBlastOutputFile{
  my $blastreportfile = $_[0];
  my $in = new Bio::SearchIO(-format => 'blast', 
                 -file   => $blastreportfile) or die; # first argument of default array passed to the subroutine (i.e. blastreportfile)

    while( my $result = $in->next_result ) {    ## $result is a Bio::Search::Result::ResultI compliant object
      while( my $hit = $result->next_hit ) {    ## $hit is a Bio::Search::Hit::HitI compliant object
        while( my $hsp = $hit->next_hsp ) {     ## $hsp is a Bio::Search::HSP::HSPI compliant object
          
          if( $hsp->percent_identity >= 30 ) {
          my $QuerySeqCoverage_percent = ($hsp->length('query')*100)/$result->query_length;
          my $evalue = $hsp->evalue;  
            if ( $QuerySeqCoverage_percent >= 0 && $evalue <= 1.0e-3) {
              $BlastReportHash{"QueryAC"}=$result->query_accession;
              $BlastReportHash{"SubjectAC"}=$hit->accession;
              #$BlastReportHash{"QueryLength"}=$result->query_length;   # Uncomment in case that the lenghts
              #$BlastReportHash{"SubjectLength"}=$hit->length;          # of Query & Subjt sequences are needed
              $BlastReportHash{"\%_SeqID"}=$hsp->percent_identity;
              $BlastReportHash{"ConservRes"}=$hsp->num_conserved;
              $BlastReportHash{"E-value"}=$hsp->evalue;
              $BlastReportHash{"Score"}=$hsp->score;
              ###
              $BlastReportHash{"\%_QuerySeqCoverage"}=$QuerySeqCoverage_percent;
              $BlastReportHash{"\%_SubjSeqCoverage"}=($hsp->length('hit')*100)/$hit->length;
              ###
              $BlastReportHash{"Query_start"}=$hsp->start('query');
              $BlastReportHash{"Query_end"}=$hsp->end('query');
              $BlastReportHash{"Subj_start"}=$hsp->start('hit');
              $BlastReportHash{"Subj_end"}=$hsp->end('hit');
              ###
              $BlastReportHash{"HSP-QueryLength"}=$hsp->length('query');
              $BlastReportHash{"HSP-SubjectLength"}=$hsp->length('hit');
              $BlastReportHash{"HSP-TotalLength"}=$hsp->length('total');
              Print_BlastOutput_Hash();
            }else{;}
          }
        }
      }
    }
}
################

################
sub Print_BlastOutput_Hash{

  open(OUTFILE,">>$OutFile") or die;
  
  if (!(-s $OutFile)){                                                             ## If file is empty add the first line containing columns' names
    print OUTFILE "QueryAC\tSubjectAC\tScore\tE-value\t%_SeqID\tConservRes\t";       #
    print OUTFILE "Query_start\tQuery_end\t%_QueryCov\tSubj_start\tSubj_end\t%_SubjCov\t";        
    print OUTFILE "HSP-QueryLength\tHSP-SubjectLength\tHSP-TotalLength\n";

    #print OUTFILE "\tQueryLength\tSubjectLength\n";      ## <<-- Uncomment this line in case that the lenghts 
                                                          ## of Query & Subjt sequences are needed (then check output format)
  }

  print OUTFILE "$BlastReportHash{'QueryAC'}\t";  ## DO NOT UNCOMMENT THIS LINE UNLESS YOU WANT TO SEE THE QUERY'S AC CODE IN EVERY OUTPUT LINE
  print OUTFILE "$BlastReportHash{'SubjectAC'}\t";
  print OUTFILE "$BlastReportHash{'Score'}\t";
  printf OUTFILE ("%.1e\t",$BlastReportHash{"E-value"});
  printf OUTFILE ("%.2f\t",$BlastReportHash{"%_SeqID"});
  print OUTFILE "$BlastReportHash{'ConservRes'}\t";
  ##
  print OUTFILE "$BlastReportHash{'Query_start'}\t";
  print OUTFILE "$BlastReportHash{'Query_end'}\t";
  printf OUTFILE ("%.2f\t",$BlastReportHash{"%_QuerySeqCoverage"});
  ##
  print OUTFILE "$BlastReportHash{'Subj_start'}\t";
  print OUTFILE "$BlastReportHash{'Subj_end'}\t";
  printf OUTFILE ("%.2f\t",$BlastReportHash{"%_SubjSeqCoverage"});
  ##
  print OUTFILE "$BlastReportHash{'HSP-QueryLength'}\t";
  print OUTFILE "$BlastReportHash{'HSP-SubjectLength'}\t";
  print OUTFILE "$BlastReportHash{'HSP-TotalLength'}\t";
  #print OUTFILE "$BlastReportHash{'QueryLength'}\t";       # uncomment in case that the lenghts
  #print OUTFILE "$BlastReportHash{'SubjectLength'}";       # of Query & Subjt sequences are needed
  print OUTFILE "\n";
  
  close(OUTFILE);
}
################

###########
### Generating a merged output file 
print "Generating a merged output file\n";

open (O,">blast.merged") or die;
print O "QueryAC SubjectAC Score E-value %_SeqID ConservRes  Query_start Query_end %_QueryCov  Subj_start  Subj_end  %_SubjCov HSP-QueryLength HSP-SubjectLength HSP-TotalLength\n";
my @reportfiles=<*.blast.report>; # reading all the blast.report files generated by the code above
my $firstline;

foreach my $file (@reportfiles){
  # Next line skips the header of the file
  # Header: QueryAC SubjectAC Score E-value %_SeqID ConservRes  Query_start Query_end %_QueryCov  Subj_start  Subj_end  %_SubjCov HSP-QueryLength HSP-SubjectLength HSP-TotalLength
  $firstline=0;
  
  open(I,$file) or warn "Could not open $file: $!\n";
  $file =~  /(.+)\.blast\.report/;
  my $ac_pfam_frag=$1;

  while(<I>){
    if($firstline>0){ # avoiding header line in blast.report files
      my @fields=split("\t",$_);
      $fields[0]=$ac_pfam_frag;
      printf O ("%s",join("\t",@fields));
    }
    $firstline++;
  }
  close(I);
  unlink $file or warn "Could not unlink $file: $!\n";
}
close(O);
###########

###########
### Adding the query seqs. without homologs at the end of the blast.merged file
###
my %queries;
my %targets;

# loading all the query seqs' names
foreach my $blastreportfile (@bastreportfile_list){
  $blastreportfile =~ /fastas\/(.+)\.fasta\./;   # parsing and extracting a base filename for later output
  $queries{$1}=1;
}

# loading the names of query seqs for which there is a homolog
open(I,"blast.merged") or die;
$firstline=0;
while(<I>){
  if($firstline>0){ # avoiding header line
    my @fields=split("\t",$_);
    $targets{$fields[0]}=1;
  }
  $firstline++;
}
close(I);

# adding to blast.merged the queries for which no homolog was found
open(O,">>blast.merged") or die;
foreach(keys %queries){
  unless (exists $targets{$_}){
    print O "$_\n";
  }
}
close(O);
###########

###########
### Generating a best.results file from the blast.merged file
###
print "Generating a best.results file\n";

open(I,"blast.merged") or die;
my @merged=<I>;
close(I);

my @bestresults;
my $prev_id="";

open(O,">blast.bestresults") or die;
print O "QueryAC SubjectAC Score E-value %_SeqID ConservRes  Query_start Query_end %_QueryCov  Subj_start  Subj_end  %_SubjCov HSP-QueryLength HSP-SubjectLength HSP-TotalLength\n";

$firstline=0;
foreach (@merged){

  if($firstline>0){
    my @fields=split("\t",$_);
    
    if($firstline==1){
      #printf O ("%s", join("\t",@fields));
      push(@bestresults, join("\t",@fields));
      $prev_id=$fields[0];
      $firstline++;
      next;
    }
    
    if($prev_id ne $fields[0]){
      #printf O ("%s", join("\t",@fields));
      push(@bestresults, join("\t",@fields));
      $prev_id=$fields[0];
    }
  }
  $firstline++;
}
print O $_ foreach(sort @bestresults);
close(O);
###########


###########
#### Adding classif and sunid from scop to best results file
####
print "Adding classif and sunid from scop to best results file\n";

my %scop;
$#bestresults=-1; # clearing the array
#######
## Loading best results file
open(F,"blast.bestresults") or die; # best results file from blast vs scop
@bestresults = <F>;
chomp(@bestresults);
close(F);
#######

#######
## Loading Scop classif file 
open(F,"/aloy/home/malonso/SCOP175/dir.cla.scop.txt_1.75") or die; # full path to scop classif file
while (<F>){
  chomp;
  if ($_ !~ /^#/ ){
    my @fields=split("\t",$_);
    $scop{$fields[0]}=[$fields[2],$fields[3],$fields[4]]; # storing {d1z5lb1}=[d.159.1.3,145523]
  }
}
close(F);
#######

#######
## Adding scop classif to the bestresults file
my $headerline=0;
my @bestresults_scop;
my @tmp;
foreach (@bestresults){
  
  if($headerline>0){ # avoiding header line
    my @fields=split("\t",$_);
    if(defined $fields[1]){ # if there is a homolog in scop
      my $scop = join("\t",@{$scop{$fields[1]}});
      my $line =join("\t",@fields[2..$#fields]);
      push(@bestresults_scop,"$fields[0]\t$fields[1]\t$scop\t$line");
    }else{
      push(@bestresults_scop,$_);
    }
  }else{$headerline++;}
}

open(O,">blast.bestresults.scop") or die;
print O "QueryAC SubjectAC PDB_segment Scop_sccs Scop_sunid Blast-score E-value %_SeqID ConservRes Query_start Query_end %_QueryCov Subj_start Subj_end %_SubjCov HSP-QueryLength HSP-SubjectLength HSP-TotalLength\n";
print O "$_\n" foreach(@bestresults_scop);

unlink ("blast.bestresults");
#### 

###########


