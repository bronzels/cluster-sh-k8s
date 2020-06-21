#!/bin/bash
prefix=$1
echo "!!!Usage: $0 sql|shell driver-memory(g)> <executor-memory(g)> <executor-cores>..."
echo current prefix:$1
echo driver-memory:$2
echo executor-memory:$3
echo executor-cores:$4
echo new prefix:$5
newprefix=$5

echo $prefix
$HIVE_HOME/bin/hive -e 'show tables' | sed -n "s/.*$newprefix\(.*\).*/\1/p" |  while read line; do hive -e "DROP TABLE IF EXISTS $line"; done
$HIVE_HOME/bin/hive -e 'show tables' | sed -n "s/.*$prefix\(.*\).*/\1/p" |  while read line; do spark-sql --conf spark.default.parallelism=20 --conf spark.sql.autoBroadcastJoinThreshold=2000000 --master spark://pro-hbase01:7077 --deploy-mode client --driver-memory "$2"g --executor-memory "$3"g --executor-cores "$4" -e "CREATE TABLE $newprefix$line STORED AS ORC AS SELECT * FROM $prefix$line"; done
