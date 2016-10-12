#!/usr/bin/perl -w
#
# usage:
# provide a txt file with uniprot ac for each seq you want to download
#

use Bio::DB::SwissProt;
use Bio::Perl;
use List::MoreUtils qw(uniq);


open(INFILE,$ARGV[0]) or die;
my @UniProtACs=<INFILE>;
close(INFILE);
chomp @UniProtACs;

# make sure there are no repeated ACs
@UniProtACs = uniq(map(uc($_),@UniProtACs));

my $c=1;
my $s=@UniProtACs;




foreach (@UniProtACs){
  my $outfilename="$_".".fasta";

  if(-e $outfilename){
    print "$outfilename\texists\n";
    $c++;
  }else{
    print "...retrieving $_ : $c of $s\n";$c++;
    $db_obj = Bio::DB::SwissProt->new;
    $seq_obj = $db_obj->get_Seq_by_acc($_);
    $seq_as_string = $seq_obj->seq;
    ##
    my $s = get_sequence('swiss',$_);
    my $desc = $s->desc();
    ##
    open(OUTFILE,">./$outfilename") or die;
    print OUTFILE ">$_|$desc\n";
    print OUTFILE "$seq_as_string\n";
    close(OUTFILE);
  }
}

