#!/bin/bash
db=datastatistic_str_$1
echo "db:$db"
mongo 10.0.0.46:27011/$db -u "admin" -p "123456" --authenticationDatabase "admin" --eval "db.dropDatabase()"
