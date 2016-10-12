#!/usr/bin/env perl
#
# Created on: 28/Mar/2011 by M.Alonso
# 
# Adding a column with PK canonial AC for each PK in the reference mapping file
# 531_G_F_SF_N_ID_AC_coords.tab
# 
# INPUT
# 531_G_F_SF_N_ID_AC_coords.tab: G_F_SF_N_ID_AC_coords
# OUTPUT:
# 531_G_F_SF_N_ID_AC_coords.tab: G_F_SF_N_ID_ACcanon_ACisof_coords
# 


use LoadFile;
use strict;
use warnings;

my %refmap;
my @fields;
my @ac;
my $no_isof;

### G_F_SF_N_ID_AC_coords
foreach(File2Array("531_G_F_SF_N_ID_AC_coords.tab")){
  @fields = split('\t',$_);
	@ac = split("",$fields[5]);
	if(6<@ac){$no_isof = join("",@ac[0..5]);}
	else{$no_isof=$fields[5];}
  printf("%s\n",join("\t",@fields[0..4],$no_isof,$fields[5],$fields[6])) ;
}
