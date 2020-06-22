#!/bin/bash
db=$1
collection=$2
echo "collection:$collection"
docker run --rm mongo:4.0 mongodump --forceTableScan -h ??? -u  root -p rootRoot!@#  --port ??? --authenticationDatabase admin -d ${db} -c ${collection} -o ~/mgdump/$collection.bak
