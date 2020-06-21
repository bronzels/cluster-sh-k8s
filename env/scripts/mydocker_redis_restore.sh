#!/bin/bash

redis_host=$1
redis_port=$2
docker_redis_container_name=$3

docker stop "$docker_redis_container_name"
rm /data/docker/redis/data/*
cp -p /app/redisaofbk/* /data/docker/redis/data
docker start "$docker_redis_container_name"
#docker rm "$docker_redis_container_name"
#docker create --privileged=true --name "$docker_redis_container_name" -p "$redis_port":6379 redis:4.0.9
#docker cp /app/redisaofbk/dump.rdb "$docker_redis_container_name":/data/
#docker start "$docker_redis_container_name"
