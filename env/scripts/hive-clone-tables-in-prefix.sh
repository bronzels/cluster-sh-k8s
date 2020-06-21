#!/bin/bash
prefix=$1
newprefix=$2
echo $prefix
echo $newprefix
$HIVE_HOME/bin/hive -e 'show tables' | sed -n "s/^$prefix\(.*\).*/\1/p" |  while read line; do echo "$newprefix$line";hive -e "DROP TABLE IF EXISTS $newprefix$line"; done
$HIVE_HOME/bin/hive -e 'show tables' | sed -n "s/^$prefix\(.*\).*/\1/p" |  while read line; do echo "$prefix$line to $newprefix$line";spark-sql --master yarn --deploy-mode client --conf spark.default.parallelism=20 --conf spark.sql.autoBroadcastJoinThreshold=2000000 -e "CREATE TABLE $newprefix$line STORED AS ORC AS SELECT * FROM $prefix$line"; done
