#!/usr/bin/env python

# imports
import sys
import os

# constants

# functions
def usage():
  print "Usage: splitquery <fasta_query_file> <query_dir>"
  print

def main():
  # Body of function main
  if len( sys.argv ) != 3:
    usage()
    sys.exit(-1)

  queryDir = sys.argv[2]
  
  if not os.path.exists(queryDir):
    os.mkdir( queryDir )

  seqFile=open( sys.argv[1] )
  counter=0
  files = set()
  print 'Processing sequences:'
  for line in seqFile:
    #print line
    if line.find('>') != -1:
      if counter != 0:
        queryfile.close()
      seqName = line[1:].strip()
      queryFileName = queryDir+'/'+ seqName +'.fasta'
      print '['+str(counter).rjust(5)+']:', seqName,' -> ',queryFileName
      if queryFileName in files:
        print "Found duplicate:",queryFileName
        sys.exit(1)
      files.add(queryFileName)
      counter += 1
      queryfile = open(queryFileName,'w')
      queryfile.write( '>'+seqName+'\n' )    
    else:
      queryfile.write( line )
  queryfile.close()
  seqFile.close()

# main stream
main()
