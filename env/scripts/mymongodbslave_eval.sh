#!/bin/bash
db=$1
evalit=$2
#echo "db:$db"
#echo "evalit:$evalit"
mongo 10.0.0.46:27011/$db -u "admin" -p "123456" --authenticationDatabase "admin" --quiet -eval "$evalit"
