#!/bin/bash
db=$1
evalit=$2
#echo "db:$db"
#echo "evalit:$evalit"
mongo dds-wz9e222b78bedd041.mongodb.rds.aliyuncs.com:3717/$db -u "root" -p 'rootRoot!@#' --authenticationDatabase "admin" --quiet -eval "$evalit"

#mongo --host dds-wz9e222b78bedd041.mongodb.rds.aliyuncs.com:3717 -u root -p 'rootRoot!@#' --authenticationDatabase admin

