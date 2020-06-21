#!/bin/bash

db_url=$1
db=$2
tableName=$3
prefix=$4

echo "db:$db,tableName:$tableName,prefix:$prefix"

hive -e "DROP table IF EXISTS $prefix$tableName"
sqoop import --connect "jdbc:mysql://$db_url:3306/$db?useSSL=false" --username liuxiangbin --password m1njooUE04vc --table $tableName -m 6 --hcatalog-database default --hcatalog-table $prefix$tableName --create-hcatalog-table --hcatalog-storage-stanza "stored as orcfile"

