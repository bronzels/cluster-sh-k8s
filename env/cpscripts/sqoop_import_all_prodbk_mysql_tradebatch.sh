#!/bin/bash

db=$1
tableName=$2
tableCols=$3
prefix=$4

echo "db:$db,tableName:$tableName,tableCols:$tableCols,prefix:$prefix"

hive -e "DROP table IF EXISTS $prefix$tableName"
sqoop import --connect "jdbc:mysql://rm-wz905j9253s6l04l6.mysql.rds.aliyuncs.com:3306/$db?useSSL=false" --username liuxiangbin --password m1njooUE04vc --table $tableName --columns $tableCols -m 6 --hcatalog-database default --hcatalog-table $prefix$tableName --create-hcatalog-table --hcatalog-storage-stanza "stored as orcfile"
