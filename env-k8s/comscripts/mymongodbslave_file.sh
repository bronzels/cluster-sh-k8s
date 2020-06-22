#!/bin/bash
db=$1
file=$2
echo "db:$db"
echo "file:$file"
docker run --rm mongo:4.0 mongo --forceTableScan hk-prod-bigdata-slave-0-234:27011/$db -u "admin" -p "123456" --authenticationDatabase "admin" $file
