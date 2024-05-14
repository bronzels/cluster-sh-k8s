#!/bin/bash
p="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
prefix=$1
ls ~/mgdump | sed -n "s/$prefix\(.*\).*/\1/p" | while read line; do $p/mymongodb_restore.sh $prefix$line; done
