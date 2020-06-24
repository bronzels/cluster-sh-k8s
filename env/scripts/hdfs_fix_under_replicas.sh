#!/bin/bash

if [ $# -eq 1 ];
then
replino=$1
else
replino=3
fi

hdfs fsck / | grep 'Under replicated' | awk -F':' '{print $1}' >> /tmp/under_replicated_files
for hdfsfile in `cat /tmp/under_replicated_files`; do echo "Fixing $hdfsfile :" ;  hadoop fs -setrep ${replino} $hdfsfile; done