# created on: 17/Mar/2011 by M.Alonso
#
# USAGE:
#   PERL5LIB env variable:
#    update PERL5LIB variable in .bashrc
#    export PERL5LIB=${PERL5LIB}:/home/malonso/phd/kinome/scripts/modules/
#
# CALLING MODULE
#   use ListCompare;
#

use strict;
use warnings;
use List::Compare;

require Exporter;
package ListCompare;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(  
                      retrieve_intersection_multiple
                      retrieve_intersection
                      retrieve_union
                  );    # Symbols to be exported by default
#

##############################
## Description
## Retrieving the intersection elements between multiple arrays.
## 
## Input:
##  - Ref. to an array of arrays.
## 
## Output:
##  - Ref. to an array containing the intersection
## 
## Usage:
##  - @intersection = @{  retrieve_intersection_multiple(\@AoA)  }
## 
sub retrieve_intersection_multiple{
  my @AoA = @{$_[0]};
  die "Empty array of array passed to retrieve_intersection_multiple()\n" if (0 == scalar @AoA);
  
  my $list_compare;
  my (@intersection, @a1, @a2);
  
  for(my $i = 0; $i <= $#AoA ; $i++){
    @a1 = @{$AoA[$i]};
    die "Empty sub-array in retrieve_intersection_multiple()\n" if (0 == scalar @a1);
    
    ### Computing intersections
    if($i==0){ ### Computing intersection between first two arrays
      $i++;
      @a2 = @{$AoA[$i]};
      die "Empty sub-array in retrieve_intersection_multiple()\n" if (0 == scalar @a2);
      $list_compare = List::Compare->new('--unsorted', '--accelerated',\@a1, \@a2);
      @intersection = $list_compare->get_intersection;
    }else{ ### Computing intersection between subsequent arrays
      $list_compare = List::Compare->new('--unsorted', '--accelerated',\@a1, \@intersection);
      @intersection = $list_compare->get_intersection;
    }
    
    ### Exit loop if the intersection array is empty
    last if (0 == scalar @intersection);
  }
  
  return \@intersection;
}
##############################

##############################
## Retrievign the intersection between the two arrays.
## @a = @{ retrieve_intersection(\@a1, \@a2) }
sub retrieve_intersection{
  my @a1 = @{$_[0]};
  my @a2 = @{$_[1]};
  die "Empty array in retrieve_intersection_multiple()\n" if (0 == scalar @a1 || 0 == scalar @a2 );
  my @intersection;
  my $list_compare = List::Compare->new('--unsorted', '--accelerated',\@a1, \@a2);
  @intersection = $list_compare->get_intersection;
  return \@intersection;
}
##############################

##############################
## Retrievign the union between the two arrays.
## @a = @{ retrieve_union(\@a1, \@a2) } 
sub retrieve_union{
  my @a1 = @{$_[0]};
  my @a2 = @{$_[1]};
  die "Empty array in retrieve_intersection_multiple()\n" if (0 == scalar @a1 || 0 == scalar @a2 );
  my @union;
  my $list_compare = List::Compare->new('--unsorted', '--accelerated',\@a1, \@a2);
  @union = $list_compare->get_union;
  return \@union;
}
##############################


1;
