#!/bin/bash

backup_db=$1
backup_file_path=$2

rm -rf "$backup_file_path/"+backup_db

mongodump -h dds-wz96c88b733b36d433330.mongodb.rds.aliyuncs.com -u root -p BbEPgA6TFkaGNIp6 --port 3717 --authenticationDatabase admin  -d "$backup_db" -o "$backup_file_path"


