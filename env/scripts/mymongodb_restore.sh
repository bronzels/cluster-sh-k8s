#!/bin/bash

restore_db=$1
backup_file_path=$2

echo "$restore_db" "$backup_file_path/$restore_db"

#mongorestore -h dds-wz96c88b733b36d433330.mongodb.rds.aliyuncs.com -u root -p BbEPgA6TFkaGNIp6 --port 3717 --authenticationDatabase admin --drop -d "$restore_db" "$backup_file_path/$restore_db"

mongorestore -h dds-wz96c88b733b36d433330.mongodb.rds.aliyuncs.com -u root -p BbEPgA6TFkaGNIp6 --port 3717 --authenticationDatabase admin --drop -d "$restore_db" "$backup_file_path"