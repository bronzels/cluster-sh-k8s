#!/bin/bash
old_hash_key=$1
new_hash_key=$2
echo "old hash key:${old_hash_key}, new hash key :${new_hash_key}"

redis-cli -h 127.0.0.1 -p 6379 del ${new_hash_key}
echo "hgetall ${old_hash_key}" | redis-cli -h 127.0.0.1 -p 6379 > myredis_hash_value_tmp.txt
hash_value=""

cat myredis_hash_value_tmp.txt | while read line
do
    hash_value="$hash_value $line"
    echo "$hash_value" >  myredis_hash_value_tmp.txt
done

cat myredis_hash_value_tmp.txt | while read line
do
    redis-cli -h 127.0.0.1 -p 6379 hset $new_hash_key  $line
done


