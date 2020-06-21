#!/bin/bash
db=$1
file=$2
echo "db:$db"
echo "file:$file"
mongo dds-wz9e222b78bedd041.mongodb.rds.aliyuncs.com:3717/$db -u "root" -p 'rootRoot!@#' --authenticationDatabase "admin" $file

#mongo --host dds-wz9e222b78bedd041.mongodb.rds.aliyuncs.com:3717 -u root -p 'rootRoot!@#' --authenticationDatabase admin

