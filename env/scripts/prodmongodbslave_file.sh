#!/bin/bash
db=$1
file=$2
echo "db:$db"
echo "file:$file"
mongo 10.0.0.46:27011/$db -u "admin" -p "123456" --authenticationDatabase "admin" $file
