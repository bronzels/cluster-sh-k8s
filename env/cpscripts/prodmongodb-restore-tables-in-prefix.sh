#!/bin/bash
p="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
prefix=$1
#$p/prodmongodb_eval.sh "db.getCollectionNames()" | sed -n "s/.*\"$prefix\(.*\)\".*/\1/p" |  while read line; do $p/prodmongodb_restore.sh $prefix$line; done
#$p/prodmongodb_eval.sh "db.getCollectionNames()" | sed -n "s/.*\"$prefix\(.*\)\".*/\1/p" |  while read line; do $p/prodmongodb_restore.sh $prefix$line; done
ls ~/mgdump | sed -n "s/$prefix\(.*\).*/\1/p" | while read line; do $p/prodmongodb_restore.sh $prefix$line; done
#ls ~/mgdump | sed -n "s/$prefix\(.*\).*/\1/p" | while read line; do echo $prefix$line; done
