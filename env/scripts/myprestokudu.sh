#!/bin/bash
export JAVA_HOME=~/jdk;export PATH=~/jdk/bin:$PATH
schema=$1
~/presto-server/bin/presto-cli --server pro-hbase05:8070 --catalog kudu --schema ${schema}
