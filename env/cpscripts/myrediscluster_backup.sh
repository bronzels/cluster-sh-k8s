#!/bin/bash
for((i=1;i<=3;i++));
do
ssh pro-hbase02 rm /app/redisaofbk/700${i}/*
ssh pro-hbase02 cp /app/redis/data/700${i}/* /app/redisaofbk/700${i}
done

for((i=4;i<=6;i++));
do
ssh pro-hbase03 rm /app/redisaofbk/700${i}/*
ssh pro-hbase03 cp /app/redis/data/700${i}/* /app/redisaofbk/700${i}
done

for((i=7;i<=9;i++));
do
ssh pro-hbase04 rm /app/redisaofbk/700${i}/*
ssh pro-hbase04 cp /app/redis/data/700${i}/* /app/redisaofbk/700${i}
done