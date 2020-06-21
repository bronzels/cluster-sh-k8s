#!/bin/bash
for((i=1;i<=3;i++));
do
ssh beta-hbase02 rm /app/redis/data/700${i}/*
ssh beta-hbase02 cp /app/redisaofbk/700${i}/* /app/redis/data/700${i}
done

for((i=4;i<=6;i++));
do
ssh beta-hbase03 rm /app/redis/data/700${i}/*
ssh beta-hbase03 cp /app/redisaofbk/700${i}/* /app/redis/data/700${i}
done

for((i=7;i<=9;i++));
do
ssh beta-hbase04 rm /app/redis/data/700${i}/*
ssh beta-hbase04 cp /app/redisaofbk/700${i}/* /app/redis/data/700${i}
done