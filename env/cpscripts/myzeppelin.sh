#!/bin/bash
echo "!!!Usage: $0 stop| $0 start <driver-memory(g)> <executor-memory(g)> <executor-cores>"
echo driver-memory:$2
echo executor-memory:$3
echo executor-cores:$4

export MASTER=spark://pro-hbase01:7077
export SPARK_SUBMIT_OPTIONS="--driver-memory $2g --executor-memory $3g --executor-cores $4 --conf spark.core.connection.ack.wait.timeout=300 --conf spark.executor.memoryOverhead=2048 --conf spark.default.parallelism=40 --conf spark.sql.autoBroadcastJoinThreshold=2000000"
if [ $1 == "start" ]; then
	
	echo "!!!Start zeppelin..."
	/app/hadoop/zeppelin/bin/zeppelin-daemon.sh start
else
	echo "!!!Stop zeppelin..."
	/app/hadoop/zeppelin/bin/zeppelin-daemon.sh stop
fi
