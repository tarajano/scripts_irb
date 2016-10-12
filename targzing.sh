#!/bin/bash 
#
# Taring and deleting files in DAli directories
#
#
for i in `cat summary.txt.list.head`
do 
 mydir=`dirname $i`
 cd $mydir
 tar czf Tar.tgz * 
 rm *.pdb *.txt *.dat log 
done
