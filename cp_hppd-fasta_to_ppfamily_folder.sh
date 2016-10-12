#!/bin/bash

## This script copies the corresponding hppd instances (PTP,DSP, LIPID or PSTP)
## to the destination folder provided as argv[1] to the script.
## 
## The instention of this script is to "group" the fasta files per PP families
## 
## I wrote it for helping me in later generating grouping the fasta files 
## for the the multiple alignmets of the 
## HPPDs for later building the phylotrees that will lately be colorified.
##
## execute the script from the folder where the individual fasta files are (e.g. P08575_PF12453_5-32.fasta,P60484_PF10409_188-349.fasta,Q86V60_PF00102_1151-1385.fasta)
##
## ./cp_hppd-fasta_to_ppfamily_folder.sh /path/to/destination/folder/
##
##

mkdir $1/ptp
mkdir $1/dsp
mkdir $1/lipid
mkdir $1/pstp

##PTP
cp ./*PF00102* $1/ptp/
cp ./*PF06617* $1/ptp/
cp ./*PF12453* $1/ptp/  
cp ./*PF04722* $1/ptp/  
cp ./*PF01451* $1/ptp/  
##DSP
cp ./*PF00782* $1/dsp/
##LIPID
cp ./*PF10409* $1/lipid/
cp ./*PF06602* $1/lipid/
##PSTP
cp ./*PF00149* $1/pstp/
cp ./*PF00481* $1/pstp/
cp ./*PF07228* $1/pstp/
cp ./*PF07830* $1/pstp/
cp ./*PF08321* $1/pstp/
cp ./*PF03031* $1/pstp/



