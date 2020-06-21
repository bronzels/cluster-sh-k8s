#!/bin/bash

if [ -n "$1" ] ;then
db="/$1"
fi
echo "db:$db"
mongo pro-hbase01:27011/$db -u "admin" -p "123456" --authenticationDatabase "admin" $file
