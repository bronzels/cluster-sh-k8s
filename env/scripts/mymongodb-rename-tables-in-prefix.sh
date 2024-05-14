#!/bin/bash
p="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
prefix=$1
newprefix=$2
echo $prefix
$p/mymongodb_eval.sh "db.getCollectionNames()" | sed -n "s/.*\"$prefix\(.*\)\".*/\1/p" |  while read line; do $p/mymongodb_eval.sh "db.$prefix$line.renameCollection(\"$newprefix$line\")"; done
