#!/bin/bash
export JAVA_HOME=~/jdk;export PATH=$PATH:~/jdk/bin
~/presto-server/bin/presto-cli --server http://pro-hbase05:8070 --catalog hive --schema default
