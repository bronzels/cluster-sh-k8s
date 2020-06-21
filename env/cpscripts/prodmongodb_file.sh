#!/bin/bash
db=$1
file=$2
echo "db:$db"
echo "file:$file"

cp $file /app/backup/mongodb/
filename=${file##*/}
docker run --rm -v /app/backup:/workdir/ -w /workdir/ mongo:4.0 mongo dds-wz9e222b78bedd041.mongodb.rds.aliyuncs.com:3717/$db -u "root" -p 'rootRoot!@#' --authenticationDatabase "admin" /workdir/mongodb/$filename

#mongo --host dds-wz9e222b78bedd041.mongodb.rds.aliyuncs.com:3717 -u root -p 'rootRoot!@#' --authenticationDatabase admin

