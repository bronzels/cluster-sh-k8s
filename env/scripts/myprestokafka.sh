#!/bin/bash
export JAVA_HOME=~/jdk;export PATH=~/jdk/bin:$PATH
~/presto-server/bin/presto-cli --server http://pro-hbase05:8070 --catalog kafka --schema default
