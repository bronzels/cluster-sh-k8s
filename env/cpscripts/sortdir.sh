#!/bin/bash
folder=$1
echo $folder
ls $folder |  while read line; do cat $folder/$line | sort -o $folder/$line.sorted;rm -f $folder/$line; done
