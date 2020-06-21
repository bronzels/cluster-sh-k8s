#!/bin/bash

backup_db=$1
backup_file_path=$2

rm -rf "$backup_file_path/"+backup_db

docker run --rm -v /app/backup:/workdir/ -w /workdir/ mongo:4.0 mongodump --forceTableScan -h ??? -u bd_datastatistic -p H7HY2TCG5Ywbx5PL --port ??? --authenticationDatabase admin -d "$backup_db" -o /workdir/mongodb
