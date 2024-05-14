#!/bin/bash
prefix=$1
echo $prefix
$HIVE_HOME/bin/hive -e 'show tables' | sed -n "s/.*$prefix\(.*\).*/\1/p" |  while read line; do hive -e "drop table \`$prefix$line\`"; done
