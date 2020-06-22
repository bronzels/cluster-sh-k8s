#!/bin/bash

redis_host=$1
redis_port=$2
docker_redis_container_name=$3

redis-cli -h "$redis_host" -p "$redis_port" save

mkdir -p /app/redisaofbk
rm /app/redisaofbk/*
cp -p /data/docker/redis/data/* /app/redisaofbk
