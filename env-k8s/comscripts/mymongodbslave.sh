#!/bin/bash

if [ -n "$1" ] ;then
db="/$1"
fi
echo "db:$db"
docker run --rm mongo:4.0 mongodump --forceTableScan hk-prod-bigdata-slave-0-234:27011/$db -u "admin" -p "123456" --authenticationDatabase "admin" $file
