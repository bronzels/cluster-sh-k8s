#!/bin/bash
p="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
prefix=$1
echo $prefix
$p/prodmongodb_eval.sh "db.getCollectionNames()" | sed -n "s/.*\"$prefix\(.*\)\".*/\1/p" |  while read line; do $p/prodmongodb_eval.sh "print(db.$prefix$line.remove({}))"; done
#$p/prodmongodb_eval.sh "db.getCollectionNames()" | sed -n "s/.*\"$prefix\(.*\)\".*/\1/p" |  while read line; do echo $prefix$line; done
