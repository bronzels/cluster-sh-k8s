#!/bin/bash
prefix=$1
echo $prefix
mykafka2_topics.sh | sed -n "s/^$prefix\(.*\).*/\1/p" |  while read line; do kafka-topics.sh --delete --zookeeper pro-hbase06:2281,pro-hbase07:2281,pro-hbase08:2281/kafka2 --topic "$prefix$line"; done
