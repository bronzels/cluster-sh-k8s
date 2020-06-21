#!/bin/bash
db=$1
tableName=$2
tableCols=$3
prefix=$4

echo "db:$db,tableName:$tableName,tableCols:$tableCols,prefix:$prefix"
hive -e "DROP table IF EXISTS $prefix$tableName"

~/sqoop/bin/sqoop import --connect "jdbc:mysql://10.0.0.51:3316/$db?useSSL=false" --username root --password 123456 --table $tableName --columns $tableCols -m 6 --hcatalog-database default --hcatalog-table $prefix$tableName --create-hcatalog-table --hcatalog-storage-stanza "stored as orcfile"

