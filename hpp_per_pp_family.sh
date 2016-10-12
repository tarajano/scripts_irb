#!/bin/bash
# 
# Counting the number of HPPs and HPP Domains in each PP family based on the Pfam domain composition of each HPP
# Provide a ac2pfam.out file as input
# ./script.sh ac2pfam.out
#

echo "Provide a ac2pfam.out file as input"
echo 

# Proteins per PP family 
echo --- Proteins per PP family ---
echo PTP:
grep -P "PF00102|PF06617|PF12453|PF04722|PF01451" $1 | awk -F "\t" '{print $1}' | sort -u | wc -l
echo DSP:
grep -P "PF00782" $1 | awk -F "\t" '{print $1}' | sort -u | wc -l
echo LIPID:
grep -P "PF10409|PF06602" $1 | awk -F "\t" '{print $1}' | sort -u | wc -l
echo PSTP:
grep -P "PF00149|PF00481|PF07228|PF07830|PF08321|PF03031" $1 | awk -F "\t" '{print $1}' | sort -u | wc -l
# P-Phosphatase Pfam domains per PP family
echo --- P-Phosphatase Pfam domains per PP family ---
echo PTP:
grep -P "PF00102|PF06617|PF12453|PF04722|PF01451" $1 | sort -u | wc -l
echo DSP:
grep -P "PF00782" $1 | sort -u | wc -l
echo LIPID:
grep -P "PF10409|PF06602" $1 | sort -u | wc -l
echo PSTP:
grep -P "PF00149|PF00481|PF07228|PF07830|PF08321|PF03031" $1 | sort -u | wc -l

