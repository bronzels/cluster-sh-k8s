#!/bin/bash

port=$1

for((i=2;i<=4;i++));
do
redis-cli -h 10.0.0.5"${i}" -p "${port}" bgsave
done