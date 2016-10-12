#!/bin/bash
# adding TER & END to the end of PDB files

for i in *.pdb;do 
echo -e "TER\nEND" >> $i
done
