#!/bin/bash
export JAVA_HOME=~/jdk;export PATH=~/jdk/bin:$PATH
schema=$1
~/presto-server-2/bin/presto-cli --server pro-hbase05:8170 --catalog kudu --schema ${schema}
