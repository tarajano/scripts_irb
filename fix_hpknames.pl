#!/usr/bin/perl -w
# fixing missing subfamily names in hpkp fasta file

my %hpks;
my @fields; 
my $hpkname;

open(F,$ARGV[0]) or die;
while(<F>){
  chomp();
  if($_ =~ /^>(.+)$/){
	  $hpkname = $1;
	  @fields = split("_",$hpkname);
		if($#fields < 3){
		  $hpkname = join("_",$fields[0],$fields[1],"",$fields[2]); 
		}
  }elsif(/^[A-Z]/){
	  $hpks{$hpkname}=$_;
  }
}
close(F);

print ">$_\n$hpks{$_}\n" foreach (sort {$a cmp $b} keys %hpks);



