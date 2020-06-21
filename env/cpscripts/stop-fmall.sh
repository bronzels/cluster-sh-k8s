#!/bin/bash
p="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#alluxio-stop.sh all
#$p/myprestoserver.sh stop
stop-hbase.sh
#stop-all-spark.sh
#stop-history-server.sh
$p/hadoop_stopall.sh
