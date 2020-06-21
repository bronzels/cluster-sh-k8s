#!/bin/bash
inputfile=$1
echo $inputfile
cat $inputfile |  while read line; do hive -e "drop table $line"; done
