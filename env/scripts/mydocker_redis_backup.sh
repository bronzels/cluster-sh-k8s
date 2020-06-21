#!/bin/bash

redis_host=$1
redis_port=$2
docker_redis_container_name=$3

redis-cli -h "$redis_host" -p "$redis_port" save

mkdir -p /app/redisaofbk
rm /app/redisaofbk/*
cp -p /data/docker/redis/data/* /app/redisaofbk
#docker cp "$docker_redis_container_name":/data/dump.rdb /app/redisaofbk
#docker stop "$docker_redis_container_name"
#docker rm "$docker_redis_container_name"
#
#docker create --privileged=true --name "$docker_redis_container_name" -p "$redis_port":6379 redis:4.0.9
#
#docker cp /app/redisaofbk/dump.rdb "$docker_redis_container_name":/data/
#
#docker start "$docker_redis_container_name"
#
#echo "$redis_host"
