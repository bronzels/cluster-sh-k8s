#!/bin/bash
db=$1
evalit=$2
#echo "db:$db"
#echo "evalit:$evalit"
docker run --rm mongo:4.0 mongo --forceTableScan hk-prod-bigdata-slave-0-234:27011/$db -u "admin" -p "123456" --authenticationDatabase "admin" --quiet -eval "$evalit"
