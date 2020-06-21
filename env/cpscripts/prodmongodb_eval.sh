#!/bin/bash
#cmd="mongo dds-wz99f509aded8c4433330.mongodb.rds.aliyuncs.com:3717/datastatistic_1_24_1 -u "root" -p "x0uFb9Hc3HE9" --authenticationDatabase "admin""
cmd="mongo 47.107.179.17:27017/datastatistic_1_3 -u "admin" -p "HXvJIsTBAh1Y2cy6" --authenticationDatabase "admin""
if [ ! -n "$1" ] ;then 
$cmd
else
$cmd --eval "$1"
fi
