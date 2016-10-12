##
## R script by M.Alonso created on 5/Dec/2011
## 
## Usage:
## R --vanilla < ~/path/to/this/script.r
##
## This script is meant to be used with the output file of the script
##  'within_hpkfams_shared_partners_shared_substrates.pl'
## This script wii generate a lattice scatter plot of shared substrates vs
## shared partners for each kinase family.
##
##

library(lattice)

##############################
## Creating functions for managing 
## tics at log scaled axes in the lattice.
## Functions taken from:
## http://lmdvr.r-forge.r-project.org/figures/figures.html
## Figures 8.3 -> 8.5
## xscale.components.log10 was modified as s/bottom/left/ for generating
## the function yscale.components.log10
##
##
logTicks <- function (lim, loc = c(1, 5)) {
  ii <- floor(log10(range(lim))) + c(-1, 2)
  main <- 10^(ii[1]:ii[2])
  r <- as.numeric(outer(loc, main, "*"))
  r[lim[1] <= r & r <= lim[2]]
}

xscale.components.log10 <- function(lim, ...) { 
  ans <- xscale.components.default(lim = lim, ...)
  tick.at <- logTicks(10^lim, loc = 1:9)
  tick.at.major <- logTicks(10^lim, loc = 1)
  major <- tick.at %in% tick.at.major
  ans$bottom$ticks$at <- log(tick.at, 10)
  ans$bottom$ticks$tck <- ifelse(major, 1.5, 0.75)
  ans$bottom$labels$at <- log(tick.at, 10)
  ans$bottom$labels$labels <- as.character(tick.at)
  ans$bottom$labels$labels[!major] <- ""
  ans$bottom$labels$check.overlap <- FALSE
  ans
}

yscale.components.log10 <- function(lim, ...) { 
  ans <- yscale.components.default(lim = lim, ...)
  tick.at <- logTicks(10^lim, loc = 1:9)
  tick.at.major <- logTicks(10^lim, loc = 1)
  major <- tick.at %in% tick.at.major
  ans$left$ticks$at <- log(tick.at, 10)
  ans$left$ticks$tck <- ifelse(major, 1.5, 0.75)
  ans$left$labels$at <- log(tick.at, 10)
  ans$left$labels$labels <- as.character(tick.at)
  ans$left$labels$labels[!major] <- ""
  ans$left$labels$check.overlap <- FALSE
  ans
}
##############################

##############################
## Moving to directory from where R is called
setwd(getwd())

## Loading data from input file
inputfile="within_hpkfams_shared_partners_shared_substrates_ppiscompl.tab"
myd <- read.table(inputfile, head=T)
attach(myd)

## Creating name for output (lattice) png file
output_png <- sub('\\.tab','.png',inputfile)
##############################

##############################
png(output_png, width=20, height=20, units = 'cm', res=300, pointsize=6)
xyplot(sharedsubstrates ~ sharedpartners|hpkfamily,
  main="Number of shared substrates vs. number of shared partners\nfor protein pairs within kinases families",
  xlab="Number of shared partners",
  ylab="Number of shared substrates",
  ## Setting font size and color of boxes headers
  par.strip.text = list(cex = 0.55,col="black"),
  ## Setting the scales
  scales=list(log=10),
  xscale.components = xscale.components.log10,
  yscale.components = yscale.components.log10
)
dev.off()
##############################
