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

require Exporter;
package DataStructuresUtils;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(
                      get_random_keys_from_hash
                    );    # Symbols to be exported by default
#

##############################
######## SUBROUTINES ######### 
##############################

##############################
### Description:
###   Retrieves random key from a hash (random sampling without replacement)
###   
### Usage:
###   rand_key = get_random_keys_from_hash(\%hash, random_keys_numb);
###   
### Input:
###   - Ref. to hash
###   - Number of random keys to be retrieved
###   
### Output:
###   - Ref. to array containing the random keys selected
###  
sub get_random_keys_from_hash{
  my %hash = %{$_[0]};
  my $key_numbs = $_[1];
  
  ### Define variables.
  my $key;
  my @selected_keys=();
  
  ### Retrieve keys from input hash.
  my @keys = keys %hash;
  
  ### Die if the number of random keys requested is larger than the
  ### number of keys in the input hash.
  die "Requested number of keys larger than keys in the hash\n" if($key_numbs > scalar @keys);
  
  ### Randomly selecting keys from hash (without replacement)
  for (my $i=0; $i <= $key_numbs-1; $i++){
    
    ### Random key selection
    $key = $keys[int rand @keys];
    push(@selected_keys,$key);
    
    ### Delete selected key from input hash and re-assign remaining keys
    ### to key array. Assuring random sampling without replacement.
    delete $hash{$key};
    @keys = keys %hash;
  }
  
  return \@selected_keys;
}
##############################




1;
