#!/bin/bash
db=datastatistic_str_$1
echo "db:$db"
docker run --rm mongo:4.0 mongo --forceTableScan hk-prod-bigdata-slave-0-234:27011/$db -u "admin" -p "123456" --authenticationDatabase "admin" --eval "db.dropDatabase()"
