#!/bin/bash

redis_host=$1
redis_port=$2
docker_redis_container_name=$3

docker stop "$docker_redis_container_name"
rm /data/docker/redis/data/*
cp -p /app/redisaofbk/* /data/docker/redis/data
docker start "$docker_redis_container_name"
