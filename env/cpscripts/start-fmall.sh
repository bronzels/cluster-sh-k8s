#!/bin/bash
p="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
$p/hadoop_startall.sh
start-hbase.sh
#start-all-spark.sh
#start-history-server.sh hdfs://hann/apphis
#$p/myprestoserver.sh start
#alluxio-start.sh all NoMount
