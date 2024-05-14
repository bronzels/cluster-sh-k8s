#!/bin/bash
set -x

ns=$1
echo "ns:${ns}"
prefix=$2
echo "prefix:${prefix}"

mykafka-topics.sh | sed -n "s/^$prefix\(.*\).*/\1/p" |  while read line; do kubectl -n default run test-kafka-producer-mqstr -ti --image=strimzi/kafka:0.18.0-kafka-2.5.0 --rm=true --restart=Never -- bin/kafka-topics.sh --zookeeper mykafka-zookeeper.${ns}:2181 --delete --topic "$prefix$line"; done
