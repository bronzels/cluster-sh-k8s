#!/bin/bash
p="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
db=$1
prefix=$2
echo "db:$db"
echo "prefix:$prefix"
#$p/prodmongodb_eval.sh "db.getCollectionNames()" | sed -n "s/.*\"$prefix\(.*\)\".*/\1/p" |  while read line; do echo $prefix$line; done
$p/prodmongodb_eval.sh "db.getCollectionNames()" | sed -n "s/.*\"$prefix\(.*\)\".*/\1/p" |  while read line; do $p/prodmongodb_dump.sh $prefix$line; done
