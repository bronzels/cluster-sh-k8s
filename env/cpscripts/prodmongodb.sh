#!/bin/bash

if [ -n "$1" ] ;then
db="/$1"
fi
echo "db:$db"
mongo dds-wz9e222b78bedd041.mongodb.rds.aliyuncs.com:3717$db -u "root" -p "rootRoot!@#" --authenticationDatabase "admin"
