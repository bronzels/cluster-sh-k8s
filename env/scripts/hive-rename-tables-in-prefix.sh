#!/bin/bash
prefix=$1
newprefix=$2
echo $prefix
echo $newprefix
$HIVE_HOME/bin/hive -e 'show tables' | sed -n "s/.*$prefix\(.*\).*/\1/p" |  while read line; do hive -e "CREATE TABLE $newprefix$line STORED AS ORC AS SELECT * FROM $prefix$line"; done
$HIVE_HOME/bin/hive -e 'show tables' | sed -n "s/.*$prefix\(.*\).*/\1/p" |  while read line; do hive -e "DROP TABLE IF EXISTS $prefix$line"; done
