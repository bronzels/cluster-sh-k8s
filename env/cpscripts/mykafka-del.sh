#!/bin/bash
ns=$1
echo "ns:${ns}"
prefix=$2
echo "prefix:${prefix}"

mykafka-topics.sh | sed -n "s/^$prefix\(.*\).*/\1/p" |  while read line; do kafka-topics.sh --delete --zookeeper ???.${ns}:2181/??? --topic "$prefix$line"; done
