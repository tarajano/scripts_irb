#!/bin/bash  

### by MAAT at 11:44 on 08/October/2012

### Input file format
### 
### CPLX  Kinase  Adap/Scaff Substrate
### GOCC  GO terms of subcellular co-localization
### DDKA  Evidences of domain-domain (DD) interactions between the kinase (K) andthe adaptor/scaffold (A) (3did)
### DDAS  Evidences of domain-domain (DD) interactions between the adaptor/scaffold (A) and the substrate (S) (3did)
### //     End of entry
### 
### 

if [ "$1" = "" ]; then
 echo "Please provide an input file"
 echo "e.g. $>./thisscript myinputfile"
 exit
fi

MYTMP=`awk -F "\t" '{if($1=="CPLX") print  $0}' $1 | suwc`
echo "Number of CPLXs: $MYTMP"

MYTMP=`awk -F "\t" '{if($1=="CPLX") print  $2}' $1 | suwc`
echo "Unique Kinases: $MYTMP"

MYTMP=`awk -F "\t" '{if($1=="CPLX") print  $3}' $1 | suwc`
echo "Unique A/S: $MYTMP"

MYTMP=`awk -F "\t" '{if($1=="CPLX") print  $4}' $1 | suwc`
echo "Unique Substrates: $MYTMP"

MYTMP=`awk -F "\t" '{if($1=="CPLX") print  $2"\n"2$3"\n"$4}' $1 | suwc`
echo "Unique Proteins: $MYTMP"

MYTMP=`awk -F "\t" '{if($1=="GOCC") print  $2}' $1 | sed 's/,/\n/g' | suwc`
echo "Unique GO::CC terms: $MYTMP"

