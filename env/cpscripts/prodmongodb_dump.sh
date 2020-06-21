#!/bin/bash
collection=$1
echo "collection:$collection"
mongodump -h dds-wz99f509aded8c4433330.mongodb.rds.aliyuncs.com -u  root -p x0uFb9Hc3HE9  --port 3717 --authenticationDatabase admin -d datastatistic_1_20 -c $collection -o ~/mgdump/$collection.bak
