# created on: 17/Mar/2011 by M.Alonso
#
# USAGE:
#   PERL5LIB env variable:
#    update PERL5LIB variable in .bashrc
#    export PERL5LIB=${PERL5LIB}:/home/malonso/phd/kinome/scripts/modules/
#
# CALLING MODULE
#   use LoadFile;
#

use strict;
use warnings;
use LoadFile;
use List::MoreUtils qw(uniq);

require Exporter;
package UniprotTools;

our @ISA       = qw(Exporter);
our @EXPORT    = qw( 
                    ac2id_hash
                    file_ac2id
                    hs_enzymes_id2ac
                    ac_list_2_id_list
                    is_canonical_uniprotAC
                    canonical_uniprotACs_in_file
                    load_uniprot_AC2ID_hash
                    load_UniprotAC_to_GOCC_annotations
                    ac2fastaseq_local
                    ac2descseq_hash_local
                    );    # Symbols to be exported by default
#


##############################
######## SUBROUTINES ######### 
##############################

##############################
### Description:
###   Retrieves a the list of human enzymes ACs as reported in the file
###   enzyme.dat (ftp://ftp.expasy.org/databases/enzyme)
### 
### Input
###   - nothing
###   
### Returns
###   - Ref. to hash containing {AC}=ID
###   
### Usage:
###  %hs_enz_id2ac = %{hs_enzymes_id2ac()}
###  
sub hs_enzymes_id2ac{
  my $enzyme_dat = '/home/malonso/phd/kinome/hpk/ec2hpk/enzyme.dat';
  my %hs_enzyme_id2ac; ### {enzAC}=enzID
  my (@fields);
  foreach my $line (LoadFile::File2Array($enzyme_dat)){
    @fields = LoadFile::splitspaces($line);
    next unless ($fields[0] eq 'DR');
    ### Removing usless fields
    ### DR   P07327, ADH1A_HUMAN;  P28469, ADH1A_MACMU;  Q5RBP7, ADH1A_PONAB;
    $line =~ s/DR\s+//g;
    $line =~ s/[,|;]//g;
    $line =~ s/\s+/ /g;
    $line =~ s/\s+$//g;
    ### P07327 ADH1A_HUMAN P28469 ADH1A_MACMU Q5RBP7 ADH1A_PONAB1
    @fields = LoadFile::splitspaces($line);
    for(my $i=1; $i <= $#fields ;$i+=2){
      $hs_enzyme_id2ac{$fields[$i-1]}=$fields[$i] if($fields[$i] =~ /HUMAN/);
    }
  }
  return \%hs_enzyme_id2ac;
}
##############################

##############################
### Description:
###   Given a list of human Uniprot ACs, return a hash with mappings AC -> ID.
###   ACs that do not find a mapping to an ID are also returned in the hash
###   as AC->AC mappings.
###   
### Input
###   - A ref to an array with the list of query ACs
###   
### Returns
###   - A ref. to hash {AC}=ID
###   - A ref. to an array containing unmapped ACs
###   
### Usage:
###   @tmp = @{ ac2id_hash(\@aclist) }
###   %ac2id = %{$tmp[0]};
###   @unmappedacs = @{$tmp[1]};
###   
sub ac2id_hash{
  use List::MoreUtils qw(uniq);
  my @query_acs = @{$_[0]};
  @query_acs = uniq @query_acs;
  
  my @unmappedacs;
  my %ac2id; ### {ac}=id
  
  ### Loading human AC 2 ID mappings
  my %map_ac2id = %{ load_uniprot_AC2ID_hash() };
  
  foreach my $ac (@query_acs){
    if(exists $map_ac2id{$ac}){
      $ac2id{$ac}=$map_ac2id{$ac};
    }else{
      $ac2id{$ac}=$ac;
      push(@unmappedacs, $ac);
    }
  }
  my @return = (\%ac2id, \@unmappedacs);
  return \@return;
}
##############################



##############################
### Description:
###   Given a reference to an array of Uniprot ACs, the function fetches
###   the corresponding desc and fasta sequences from a local uniprot
###   fasta file.
### 
### Usage:
###  @tmp = @{  ac2descseq_hash_local(\@acs, "/path/to/uniprotfile/with/sequences.fasta")  }
###  %ac2descseq_hash = %{$tmp[0]}
###  @notfoundacs = @{$tmp[1]}
### 
### Returns
###   - A ref. to hash of array with the structure: {AC}=[desc, sequence]
###   - A ref. to an array with the ACs not found in the provided uniprot file.
### 
### 
### 
sub ac2descseq_hash_local{
  use Bio::SeqIO;
  use List::MoreUtils qw(uniq);
  
  my @input_ACs= uniq @{$_[0]}; ## List of query ACs.
  @input_ACs= uniq @input_ACs;
  
  my $source_fasta_file=$_[1]; ## Path to source fasta file
  
  my ($ac, $id, $primaryac, $desc);
  
  my (@fasta_header, @fields, @entry_acs, @notfoundacs);
  
  my %query_acs; ### {ac}=1
  my %return_hash_ac2descseq; ### {ac}=[desc, seq]
  
  #############################
  ### Simple checking for existence of input file
  unless(-e $source_fasta_file ){
    die  "  Source fasta file not found in provided path. \n  Please check path: $source_fasta_file\n\n"; 
  }
  #############################
  
  #############################
  ### Creating hash from the list of query ACs.
  foreach (@input_ACs){ $query_acs{$_}=1; }
  #############################
  
  ##########
  ### Reading from the uniprot.fasta file
  print "Reading the uniprot.fasta file\n";
  my $in  = Bio::SeqIO->new(-file => $source_fasta_file, -format => 'Fasta');
  
  ## looking for desired ACs
  print "Retrieving sequences of ACs ... may take some time\n";
  
  while (my $seq = $in->next_seq()) {
    
    ### A work around to get the primary AC and Description of the entry
    my @fasta_header = split('\|',$seq->id); ###  >sp|P01892|1A02_HUMAN|Q53Z42,O78126|HLA class ...
    $primaryac = $fasta_header[1];
    $id = $fasta_header[2];
    $desc = $fasta_header[4]." ".$seq->description();
    
    ### Clearing array of primary and secondary acs
    @entry_acs=(); 
    
    ### Collecting primary AC
    push (@entry_acs, $fasta_header[1]);
    
    ### Collecting secondary ACs (if any)
    if($fasta_header[3] ne ""){ @fields = LoadFile::splitcomma($fasta_header[3]); push (@entry_acs, @fields); }
    
    ### Checking if any of the ACs (either primary or secondary) of
    ### current entry is in the query list.
    foreach $ac (@entry_acs){
      
      ### If current AC is in query list, print out its info. and sequence
      if(exists $query_acs{$ac}){
        
        $return_hash_ac2descseq{$primaryac}=[$id, $desc, $seq->seq];
        
        ### Once the sequence for current query AC is found, remove the 
        ### AC from the query list and also remove its secondary ACs (if any).
        foreach(@entry_acs){delete($query_acs{$_})};
        
        ### Finish the script if all query ACs had been already retrieved.
        last if(0 == scalar keys(%query_acs));
      }
    }
  }
  #########
  
  @notfoundacs = sort {$a cmp $b} keys %query_acs;
  
  return [\%return_hash_ac2descseq, \@notfoundacs];
  
}
##############################

##############################
### Description:
###   Given a file with a list of Uniprot ACs, 
###   fetches the corresponding fasta sequences from a local uniprot
###   fasta file.
### 
### Usage:
###   ac2fastaseq_local("AC | /path/to/fileofacs", "/path/to/uniprotfile/with/sequences.fasta")
### 
### Returns
###   - If only an AC is given, returns a fasta file with the corresponding sequence
###   - If a file with a list of ACs is given, returns a file with all fasta sequences
###     and a zipped file with the sequence for each independent AC.
###   - A file with the ACs for which no sequence was found.
### 
### Note:
###   - ACs of splice variants are not considered
### 
### 
sub ac2fastaseq_local{
  use Bio::SeqIO;
  
  my $input_AC=$_[0]; ## Path to file with list of query ACs.
  my $source_fasta_file=$_[1]; ## Path to source fasta file
  my $fasta_outfile = $input_AC.".FASTA";
  
  my ($ac_prim, $ac);
  my (@fasta_header, @fields, @entry_acs);
  my %query_acs;
  
  #############################
  ### Simple checking for existence of input files
  unless(-e $input_AC && -e $source_fasta_file ){
    die "  Usage:\n  ./thisscript ACs.list /path/to/source/uniprot_sequences.fasta \n\n\n";
  }
  #############################
  
  #############################
  ### Creating hash from the list of query ACs.
  foreach (LoadFile::File2Array($input_AC)){ $query_acs{$_}=1; }
  #############################
  
  #############################
  ### Testing if an output file already exists and creating a new one time tagged
  if(-e $fasta_outfile){
    my $date = `date '+%d-%b-%Y.%H.%M'`;
    chomp($date);
    $fasta_outfile=$fasta_outfile."_".$date;
  }
  #############################
  
  open(OUT_ALL_ACS,">$fasta_outfile") or die;
  ##########
  ### Reading from the uniprot.fasta file
  print "Reading the uniprot.fasta file\n";
  my $in  = Bio::SeqIO->new(-file => $source_fasta_file,-format => 'Fasta');
  my @ACsize;
  my $found=0;
  
  ## looking for desired ACs
  print "Searching sequences of ACs ... make take some time\n";
  while (my $seq = $in->next_seq()) {
    my @fasta_header = split('\|',$seq->id); ###  >sp|P01892|1A02_HUMAN|Q53Z42,O78126|HLA class ...
    @entry_acs=(); ### Clearing array
    
    ### Collecting primary AC
    push (@entry_acs, $fasta_header[1]);
    ### Collecting secondaty ACs (if any)
    if($fasta_header[3] ne ""){ @fields = LoadFile::splitcomma($fasta_header[3]); push (@entry_acs, @fields); }
    
    ### Checking if any of the ACs (either primary or secondary) of
    ### current entry is in the query list.
    foreach $ac (@entry_acs){
      
      ### If current AC is in query list, print out its info. and sequence
      if(exists $query_acs{$ac}){
        $found++;
        print OUT_ALL_ACS ">".$seq->id." ".$seq->desc."\n".$seq->seq."\n";
        
        open(OUT_SING_AC, ">$ac.fasta") or die;
        print OUT_SING_AC ">".$seq->id." ".$seq->desc."\n".$seq->seq."\n";
        close(OUT_SING_AC);
        
        ### Once the sequence for current query AC is found, remove the 
        ### AC it from the query list and also remove its secondary ACs (if any).
        foreach(@entry_acs){delete($query_acs{$_})};
        
        ### Finish the script if all query ACs had been already retrieved.
        last if(0 == scalar keys(%query_acs));
      }
    }
  }
  #########
  close(OUT_ALL_ACS);
  
  ### Zipping together all fasta output files of individual ACs
  system("tar czf $input_AC.tgz *.fasta");
  system("rm *.fasta");
  
  ##########
  ### ACs not found in uniprot file
  if(0 < scalar keys %query_acs){
    my $notfoundfile = $input_AC.".notfound";
    open(NF,">$notfoundfile");
    print NF "--- ACs not found in uniprot file --- \n";
    print NF "$_\n" foreach(sort keys %query_acs);
    close(NF);
  }
  #########
}
##############################








##############################
### Load canonical Uniprot AC from input file.
### The Uniprot ACs in the input file must be surrounded
### by space-type (\S) characters
### 
### Input: 
### Path to the file to be mapped
### 
### Returns:
### A ref. to array containing the canonical Uniprot ACs found in file.
### 
### Usage
### @array = @{  grab_canonical_uniprotACs(pathtoinputfile)  };
### 
### 
sub canonical_uniprotACs_in_file{
  use List::MoreUtils qw(uniq);
  my $infile =$_[0];
  my ($flag_is_uniprotAC);
  my (@fields, @tmp, @string, @uniprotACs);
  
  foreach(LoadFile::File2Array($infile)){
    ### Splitting on any space-type character
    @fields = uniq LoadFile::splitspaces($_);
    foreach (uniq @fields){
      ### Save current string if it is likely to be a canonical uniprot AC
      $flag_is_uniprotAC = is_canonical_uniprotAC($_);
      if($flag_is_uniprotAC == 1){ push(@tmp, $_); }
    }
  }
  @uniprotACs = uniq @tmp;
  return \@uniprotACs;
}
##############################

##############################
### Test whether a given string 
### is likely to be a canonical Uniprot AC
### 
### Input:
###   A string
### 
### Returns
###   0 if NOT LIKELY to be a canonical Uniprot AC
###   1 if LIKELY to be a canonical Uniprot AC
### 
sub is_canonical_uniprotAC{
  use List::MoreUtils qw(uniq);
  my $string = $_[0];
  my $flag=0;
  my @string;
  
  ### Returns FALSE if string not of six characters
  return 0 if (6!=length($string));
  
  ### Split the string
  @string = split("", $string);
  
  ### Returns FALSE if string does not start with capital and ends with digit
  return 0 unless ($string[0] =~ /[A-Z]/ && $string[5] =~ /[0-9]/);
  
  ### Check that the remaining characters of the string are either capital or digits
  foreach(uniq @string[1..4]){
    unless ($_ =~ /[A-Z]/ || $_ =~ /[0-9]/){ $flag++; last; }
  }
  
  if($flag == 0){ return 1;} ### String is likely to be a canonical Uniprot AC
  else{return 0;} ### String is not likely to be a canonical Uniprot AC
}
##############################

##############################
### Returns a reference to hash
### 
### {ac}=[CCGOterms]
### 
sub load_UniprotAC_to_GOCC_annotations{
  #my $gofile = "/aloy/scratch/malonso/scaffolds/ptck_q_0905/scheme3/validation_of_potential_AS/hs_GOannot_proteome/humanproteome.ac2go";
  my $gofile = "/aloy/home/malonso/phd_proj_dbs/uniprot/uniprot_2011_11/hs_uniprot_2011_11_AC2GO.map";
  my @fields;
  my %ac2go; ## {ac}=[GOterms]
  print "Loading UniprotAC to GOCC annotations\n";
  foreach(LoadFile::File2Array($gofile)){
    @fields = LoadFile::splittab($_);
    push(@{$ac2go{$fields[0]}}, $fields[2]) if($fields[1] eq "CC");
  }
  return \%ac2go;
}
##############################

##############################
### Maps ACs to IDs of specified columns in a tab-delimited file.
### Input:
###   tab-demilited file
###   the numbers of the columns that must be mapped to IDs
###
### Output:
###   tab-demilited file (ACs2IDs)
###
### Returns:
###   The path to the outputfile
###
### Usage
###   file_ac2id(pathtoinputfile, [targetcol_1, targetcol_2, ... targetcol_N ])
### 
sub file_ac2id{
  
  my($ac, $id, $tmp, $input_file_number_of_columns, $path_to_input_file, $path_to_output_file);
  my (@fields, @tmp, @target_columns, @input_file, @output_file);
  my %map_ac2id;
  
  $path_to_input_file = $_[0];
  @target_columns = @{$_[1]};
  
  $path_to_output_file = $path_to_input_file.".ac2id";
  
  @input_file = LoadFile::File2Array($path_to_input_file);
  $input_file_number_of_columns = UniprotTools::input_file_number_of_columns($input_file[0]);
  die "Subroutine file_ac2id() died.\nThere is at least one column out of file range in input file: $path_to_input_file \n" if( grep {$_ > $input_file_number_of_columns} @target_columns);
  
  ### Loading uniprot ACs 2 IDs mappings
  %map_ac2id = %{UniprotTools::load_uniprot_AC2ID_hash()};
  
  ### Performing AC 2 ID mappings
  print "Mapping ACs to IDs\n";
  @output_file = @{ UniprotTools::mapping_columns_ac2id(\@target_columns, \@input_file, \%map_ac2id) };
  
  ### Printing output file
  print_mapped_file(\@output_file, $path_to_input_file);
  
  return $path_to_output_file;
}
##############

##############
### Helper function for mapping ACs to IDs in the columns of an input file.
### This function is called by the subroutine file_ac2id.
### 
### Input:
###   - a ref. to array with the numbers of the target colums.
###   - a ref. to array that contains the target file.
###   - a ref. to hash containing the dictionary of mappings {ac}=id
### 
### Returns:
###   a ref. to array that contains the target file with ACs mapped to IDs.
### 
sub mapping_columns_ac2id{
  my @tg_cols = @{$_[0]}; ### Target columns
  my @infile = @{$_[1]}; ### Input file
  my %map_ac2id = %{$_[2]}; ### Mappings
  
  my @taget_columns_idx = map{$_ - 1} @tg_cols; ### Converting target columns numbers to indexes.
  my (@tmpfields, @mapped);
  
  foreach my $line (@infile){
    @tmpfields = LoadFile::splittab($line);
    ## Mapping ACs in each column.
    foreach my $col (@taget_columns_idx){ $tmpfields[$col] = $map_ac2id{$tmpfields[$col]} if (exists $map_ac2id{$tmpfields[$col]}); }
    ## Filling output array
    push(@mapped, LoadFile::jointab(@tmpfields));
  }
  return \@mapped;
}
##############

##############
### Retrieving number of columns in input file.
### Input: a single line of the input file
### Output: the number of colums in input file
sub input_file_number_of_columns{ return scalar LoadFile::splittab($_[0]); }
##############

##############
## Printing output file
sub print_mapped_file{
  my @outfile = @{$_[0]};
  my $path2outfile = $_[1].".ac2id";
  
  open(O, ">$path2outfile") or die;
  print O "$_\n" foreach (sort @outfile);
  close(O);
}
##############
##############################

#############################
### Loading Uniprot_parsed_lines file
### 1433B_HUMAN|P31946|P31946;A8K9K2;E1P616| etc
### 
### Input:
###  Uniprot_parsed_lines file
###
### Returns:
###  Ref. to hash containing AC 2 ID mappings {AC}=ID
###
### Usage:
###  %map_ac2id = %{ load_uniprot_AC2ID_hash() };
###
sub load_uniprot_AC2ID_hash{
  my ($ac, $id, $tmp);
  my (@fields, @acs);
  my %map_ac2id;
  
  print "Loading Uniprot_parsed_lines file\n";
  
  foreach(LoadFile::File2Array("/aloy/home/malonso/phd_proj_dbs/uniprot/uniprot_2011_11/sprot_HUMAN_parsed_lines")){
    @acs=();
    @fields  = split('\|', $_);
    
    ### Uniprot ID
    ($id, $tmp) = LoadFile::splitunderscore($fields[0]);
    
    ## Retrieving Uniprot primary AC
    push(@acs, $fields[1]);
    
    ### Retrieving  Uniprot secondary ACs (if any)
    if($fields[2] ne ""){ push(@acs, LoadFile::splitsemicolon($fields[0])); }
    
    ### Storing mappings
    foreach (@acs){ $map_ac2id{$_}=$id;}
  }
  return \%map_ac2id;
}
#############################


##############################
## Converts a list of ACs to IDs.
## ACs without mapping to IDs will be returned as ACs.
## Elements in the list will not be made unique.
sub ac_list_2_id_list{
  my ($ac, $id, $tmp);
  my @target_ac_list=@{$_[0]};
  my (@fields, @mapped);
  my %map_ac2id;
  
  %map_ac2id = %{load_uniprot_AC2ID_hash()};
  
  ## Mapping (when possible)
  ## and filling output array.
  foreach $ac (@target_ac_list){
    if(exists $map_ac2id{$ac}){
      push(@mapped, $map_ac2id{$ac});
    }else{
      push(@mapped, $ac);
    }
  }
  return \@mapped;
}
##############################




1;
