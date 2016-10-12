#!/usr/bin/env perl
#
#
#
use strict;
use warnings;

##### loading the scanpfam output files
#my @phosscanpfam=</aloy/scratch/malonso/pphosphatase/ec_txt_hugo/fastas/*pfamscan.out>; # path to scanpfam output files
my @phosscanpfam=</aloy/scratch/malonso/pphosphatase/phbase/fastas/*pfamscan.out>; # path to scanpfam output files
my %ppPfam=(
'PF06602' => 'Myotub-related',
'PF10409' => 'PTEN_C2',
'PF00102' => 'Y_phosphatase',
'PF00149' => 'Metallophos',  
'PF00481' => 'PP2C',    
'PF00782' => 'DSPc',           
'PF01451' => 'LMWPc',           
'PF03031' => 'NIF',          
'PF04722' => 'Ssu72',
'PF06617' => 'M-inducer_phosp',
'PF07228' => 'SpoIIE',
'PF07830' => 'PP2C_C',
'PF08321' => 'PPP5',
'PF09013' => 'YopH_N',
'PF12453' => 'PTP_N');

open(F,$ARGV[0]) or die;
my @acs =<F>;
chomp(@acs);
close(F);

foreach my $ac (@acs){
  foreach my $file (@phosscanpfam){
    if($file =~ /$ac/){
      open(F,$file) or die;
      while(<F>){
        chomp;
        #fields: sp|A4D256|CC14C_HUMAN DSPc  3.2e-15 ? 316 443 PF00782.13
        my @fields = split ("\t",$_);
        my ($pfamdom,$tmp)=split('\.',$fields[6]);
        print "$_\n" if(exists $ppPfam{$pfamdom});
      }
      close(F);
    }
  }
}












