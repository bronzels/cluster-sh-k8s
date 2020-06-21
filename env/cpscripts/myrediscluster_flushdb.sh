#!/bin/bash
prefix=$1
echo $prefix

for((i=1;i<=3;i++));
do
echo "flushdb" | redis-cli -h pro-hbase02 -p 700${i}
done

for((i=4;i<=6;i++));
do
echo "flushdb" | redis-cli -h pro-hbase03 -p 700${i}
done

for((i=7;i<=9;i++));
do
echo "flushdb" | redis-cli -h pro-hbase04 -p 700${i}
done
