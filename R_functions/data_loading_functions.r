#
# created on: 02/Aug/2012 at 11:23 by M.Alonso
#
# This file contains functions to facilitate loading
# data from text files to R objects.
#


### Loading requiered libraries
#library("")
#library("")
### Loading required source files (functions, etc)
#source("")


##############################
### List of functions:

# f_xcol_file_to_list

##############################



##############################
### Importing a file with unknown
### number of colums into a list.
### The first is the key for each 
### list element.
###
### Input File e.g.:
### KEYS VALUES
### key1 val1 val2 val3 val4
### key2 val1 val2 val3 
### key3 val1 val2 val3 val4  val5
### (First line is header)
### (Lines starting with '#' are ignored)
###
### Arguments:
### path_to_input_file
### field delimiter: space, coma, tab, etc (default, space)
### 
### Value:
### A list.
###
### Import method adapted from: 
### http://stackoverflow.com/questions/6602881/text-file-to-list-in-r
### http://stackoverflow.com/questions/1874443/import-data-into-r-with-an-unknown-number-of-columns
###
f_xcol_file_to_list <- function(inputfile, field_delimiter=" " ){
  inputfile_max_col <- max(count.fields(inputfile, sep=field_delimiter))
  dat <-read.table(inputfile, skip=1, fill=TRUE, col.names=1:inputfile_max_col, stringsAsFactors=FALSE, comment.char="#")
  nams <- as.character(dat[, 1]) # Fetching list keys from first colum
  dat <- dat[, -1] # Removing the fist column
  my_list <- split(dat, seq_len(nrow(dat))) # Generating the list
  my_list <- lapply(my_list, function(x) x[!is.na(x)]) # Dropping NA 
  names(my_list) <- nams # Assinging list keys
  rm(dat, nams, inputfile_max_col)
  return(my_list)
}
##############################





