#!/usr/bin/env python

# imports
import os
import sys
import subprocess

# constants

# functions
def usage(prog):
  print "Usage: "+os.path.basename(prog)+" <your_set.fasta> <uniprot.fasta> <output_file>"
  print
  
def main():
  if len(sys.argv) != 4:
    usage(sys.argv[0])
    sys.exit(1)

  smallSetFilename = sys.argv[1]
  bigSetFilename   = sys.argv[2]
  outputFilename   = sys.argv[3]
  
  smallSetDictionary = {}
  
  sys.stdout.write( "Loading "+smallSetFilename+"...\n" ); sys.stdout.flush()
  seqLabel = ""
  seqFile = open( smallSetFilename )
  counter = 0
  for line in seqFile:
    if line.find(">") != -1:
      if seqLabel != "":
        #print "Adding:'"+seq+"' -> "+seqLabel
        if seq in smallSetDictionary:
          print "WARNING! Small set contains duplicates ("+seqLabel+" == "+str(smallSetDictionary[seq])+")."
          #sys.exit(1)
        smallSetDictionary.setdefault(seq,set()).add(seqLabel)
        counter += 1
        if counter % 1000 == 0:
          print counter,"done"
      seqLabel = (line[1:].strip().split())[0]
      seq = ""
    else:
      seqToAdd = line.strip()
      if seqToAdd[-1] == "*":
        seqToAdd = seqToAdd[:-1]
      seq += seqToAdd
  seqFile.close()
  if seqLabel != "":
    smallSetDictionary.setdefault(seq,set()).add(seqLabel)
  print "done."
  
  mapping = {}
  
  sys.stdout.write( "Scanning "+bigSetFilename+"...\n" ); sys.stdout.flush()
  seqLabel = ""
  seqFile = open( bigSetFilename )
  counter = 0
  for line in seqFile:
    if line.find(">") != -1:
      if seqLabel != "":
        #print "Adding:'"+seq+"' -> "+seqLabel
        if seq in smallSetDictionary:
          for m in smallSetDictionary[seq]:
            mapping.setdefault(m,set()).add(seqLabel)
        counter += 1
        if counter % 500000 == 0:
          print counter,"done"
      #print line
      seqLabel = (line[1:].strip().split("|"))[1]
      seq = ""
    else:
      seq += line.strip()
  seqFile.close()
  if seqLabel != "":
    if seq in smallSetDictionary:
      for m in smallSetDictionary[seq]:
        mapping.setdefault(m,set()).add(seqLabel)
  print "done."

  outputFile = open( outputFilename, "w" )
  for m in mapping:
    for t in mapping[m]:
      outputFile.write( "%s\t%s\n" % (m, t) )
  outputFile.close()

main()
