#!/bin/bash
p="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
prefix=$1
newprefix=$2
echo $prefix
$p/prodmongodb_eval.sh "db.getCollectionNames()" | sed -n "s/.*\"$prefix\(.*\)\".*/\1/p" |  while read line; do $p/prodmongodb_eval.sh "db.$prefix$line.find().forEach(function(x){db.$newprefix$line.insert(x);});cnt=db.$prefix$line.find().count();print($prefix$line+"="+cnt);cntnew=db.$newprefix$line.find().count();print($newprefix$line+"="+cntnew);"; done
