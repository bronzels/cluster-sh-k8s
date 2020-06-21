#!/bin/bash
#set -x
curr=$PWD
cd $1
for FILE in `find ./ -name "*.jar"`
  do
  echo $FILE
  jar -tf $FILE |grep $2
  done
cd $curr
