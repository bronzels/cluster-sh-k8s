#!/bin/bash
p="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
curr=$PWD
folder=$1
prefix=$2
old2sed=$3
new2sed=$4
echo "folder:$folder"
echo "prefix:$prefix"
echo "old2sed:$old2sed"
echo "new2sed:$new2sed"
cd $folder
ls | sed -n "s/$prefix\(.*\).*/\1/p" | while read line; do sed -i 's#'$old2sed'#'$new2sed'#g' $prefix$line; done
cd $curr
