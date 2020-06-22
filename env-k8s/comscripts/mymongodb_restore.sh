#!/bin/bash

restore_db=$1
backup_file_path=$2

echo "$restore_db" "$backup_file_path/$restore_db"

docker run --rm -v /app/backup:/workdir/ -w /workdir/ mongo:4.0 mongorestore -h ??? -u "root" -p "rootRoot!@#" --port ??? --authenticationDatabase admin --drop -d "$restore_db" /workdir/mongodb/${restore_db}
