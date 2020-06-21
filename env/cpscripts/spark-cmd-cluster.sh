#!/bin/bash
echo "!!!Usage: $0 sql|shell driver-memory(g)> <executor-memory(g)> <executor-cores>..."
echo cmd:$1
echo driver-memory:$2
echo executor-memory:$3
echo executor-cores:$4
echo other args:$5

spark-$1 --master spark://pro-hbase01:7077 --deploy-mode client --conf spark.default.parallelism=20 --conf spark.sql.autoBroadcastJoinThreshold=2000000 --driver-memory "$2"g --executor-memory "$3"g --executor-cores "$4" $5
