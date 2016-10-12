##
## Script generated starting from the one created on Dic.2010 by D.Rossell initially intented for generating heatmaps
## of avg(flex_rmsd) obtained from Fam.vs.Fam structural superpositions of HPKDs.
## 
## Usage:
## R --vanilla < Rscript.R

library(pvclust)
library(gplots)
library(MASS)

## libraries needed for clustering the dendrograms using Spearman correlation 
source("http://www.is.titech.ac.jp/~shimo/prog/pvclust/pvclust_unofficial_090824/pvclust.R")
source("http://www.is.titech.ac.jp/~shimo/prog/pvclust/pvclust_unofficial_090824/pvclust-internal.R")


spearman_funct <- function(x, ...) {
  x <- as.matrix(x)
  #if you have NA's in your dataset change the "use" to "pairwise.complete.obs" to use as much information as possible
  res <- as.dist(1 - cor(x, method = "spearman", use = "everything"))
  res <- as.dist(res)
  attr(res, "method") <- "spearman"
  return(res)
}


drawDendogram <- function(filename) {
  ## Loading data file
  z <- read.table(filename,header=FALSE,sep='\t')
  ## Reading HPK families' names
  n <- unique(as.character(z[,2]))
  ## Defining a matrix of nrow=ncol (hpk families)
  zmat <- matrix(0,nrow=length(n),ncol=length(n))
  colnames(zmat) <- rownames(zmat) <- unique(as.character(z[,2])) #assign rownames, colnames
  
  ## Populating the matrix
  for (i in 1:nrow(z)) {
    zmat[z[i,2],z[i,4]] <- z[i,5]
    zmat[z[i,4],z[i,2]] <- z[i,5]
  }

  ## Building & clustering the dendrogram
  tree <- pvclust(zmat, method.dist=spearman_funct, method.hclust="average", nboot=500)
  ## Plotting the dendrogram
  plot(tree)
  pvrect(tree,alpha=0.95)

  ## Applying lables
  mtext('51 HPK Families. DALI AVG (rigid rmsd) nboot=500',side=3,line=0.4)
  #mtext('text',side=2,line=0.3)
  #mtext('text',side=1,line=2.5)
  #mtext('text',side=4,line=0.5)
}

#fnames <- read.table('Rdat.list',header=FALSE)
#fnames <- as.character(fnames[,1])
#fnamesout <- sub('\\.Rdat','.dend.pdf',fnames)

#for (i in 1:length(fnames)) {
#  pdf(fnamesout[i], family='Courier', pointsize=7)
#  #postscript(fnamesout[i], family='Courier', pointsize=10)
#  drawDendogram(fnames[i])
#  dev.off()
#}

#### 
fnames="pathtofile.dat"
fnamesout <- sub('\\.dat','.dend.pdf',fnames)
pdf(fnamesout[i], family='Courier', pointsize=7)
drawDendogram(fnames[i])
dev.off()










