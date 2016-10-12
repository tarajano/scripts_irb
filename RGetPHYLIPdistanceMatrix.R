## By MAAT 15 Feb 2011
##
## Script generated starting from the one created on Dic.2010 by D.Rossell initially intented for generating heatmaps
## 
## Loading a pairwise matrix and printing it out to a cvs file 
##
## Usage:
## R --vanilla < script.R
##
## NOTE: 
## 
## The number of leaves must be added at the beggining of resutling fiel for complying 
## with the .dist format
##

library(MASS)

load_print_matrix <- function(filename) {
  ## Loading data file
  z <- read.table(filename,header=FALSE,sep='\t')
  ## Reading HPK families' names
  n <- unique(as.character(z[,1]))
  ## Defining a matrix of nrow=ncol (hpk families)
  zmat <- matrix(0,nrow=length(n),ncol=length(n))
  colnames(zmat) <- rownames(zmat) <- unique(as.character(z[,1])) #assign rownames, colnames
  
  ## Populating the matrix
  for (i in 1:nrow(z)) {
    zmat[z[i,1],z[i,2]] <- z[i,4]
    zmat[z[i,2],z[i,1]] <- z[i,4]
  }
  
  ## Printing out the matrix
  ## in order to make it a 
  write.table(zmat, file = "rapido_vs_dali_rigid_rmsd_no_aPKs.dist", sep = " ", quote = FALSE, row.names = TRUE, col.names = FALSE)
}
#### 

fnames="rapido_vs_dali_rigid_rmsd_no_aPKs.dat"
load_print_matrix(fnames)










