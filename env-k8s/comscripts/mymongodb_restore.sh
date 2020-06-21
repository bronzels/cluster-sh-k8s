#!/bin/bash

restore_db=$1
backup_file_path=$2

echo "$restore_db" "$backup_file_path/$restore_db"

docker run --rm -v /app/backup:/workdir/ -w /workdir/ mongo:4.0 mongorestore -h dds-wz9e222b78bedd041.mongodb.rds.aliyuncs.com -u "root" -p "rootRoot!@#" --port 3717 --authenticationDatabase admin --drop -d "$restore_db" /workdir/mongodb/${restore_db}
