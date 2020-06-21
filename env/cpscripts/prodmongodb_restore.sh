#!/bin/bash
folder=$1
echo "folder:$folder"
mongorestore -h dds-wz99f509aded8c4433330.mongodb.rds.aliyuncs.com -u  root -p x0uFb9Hc3HE9  --port 3717 --authenticationDatabase admin ~/mgdump/"$folder"
