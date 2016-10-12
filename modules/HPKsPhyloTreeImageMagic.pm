# created on: 24/01/2012 by M.Alonso
#
# USAGE:
#   PERL5LIB env variable:
#    update PERL5LIB variable in .bashrc
#    export PERL5LIB=${PERL5LIB}:/home/malonso/phd/kinome/scripts/modules/
#
# CALLING MODULE
#   use HPKsUtils;
#

use strict;
use warnings;
use List::MoreUtils qw(uniq);

use LoadFile;

require Exporter;
package HPKsPhyloTreeImageMagic;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(  
                      load_hpk_phylotree_image
                      write_hpk_phylotree_image
                      load_image_magic_colors_list
                      load_image_magic_eye_capturing_colors_list
                      );    # Symbols to be exported by default
#

##############################
### Description:
###   Writes to an ouput file with the image of canonical phylogenetic classification of HPKs.
###   
### Usage:
###   $hpk_image = write_to_hpk_image($imagemagic_obj, "outputfilename");
###   
### Input:
###   - An object of the type Image::Magick
###   - The path/name to an output file
###   
### Output:
###  - Prints a png file
###  
sub write_hpk_phylotree_image{
  my $image_object = $_[0];
  my $output_image_file = $_[1];
  open(IMAGE, ">$output_image_file.png");
  $image_object->Write(file=>\*IMAGE, filename=>$output_image_file);
  close(IMAGE);
}
##############################

##############################
### Description:
###   Loads the color names recognized by Image Magic.
###   
### Usage:
###   @colors = @{load_image_magic_colors_list};
###   
### Output:
###  Returns a ref to array with the list of colors
###  
sub load_image_magic_colors_list{
  ### http://www.imagemagick.org/script/color.php
  my @colors = LoadFile::File2Array("/home/malonso/phd/kinome/hpk/ePKtree/imagemagic/ImageMagicColors.list");
  return \@colors;
}
sub load_image_magic_eye_capturing_colors_list{
  ### http://www.imagemagick.org/script/color.php
  my @colors = LoadFile::File2Array("/home/malonso/phd/kinome/hpk/ePKtree/imagemagic/ImageMagicColors_eye_capturing_colors.list");
  return \@colors;
}

##############################

##############################
### Description:
###   Loads the image of canonical phylogenetic classification of HPKs.
###   The image is the one provided in Manning G. et al. Science 2001
###   
### Usage:
###   $hpk_image = load_hpk_image();
###   
### Input:
###   
### Output:
###   Returns an object of the type Image::Magick
###  
sub load_hpk_phylotree_image{
  my $image = Image::Magick->new;
  open(IMAGE, '/home/malonso/phd/kinome/hpk/ePKtree/imagemagic/hpk_tree_manning_ePK_aPK.png');
  $image->Read(file=>\*IMAGE);
  close(IMAGE);
  return $image;
}
##############################




1;
