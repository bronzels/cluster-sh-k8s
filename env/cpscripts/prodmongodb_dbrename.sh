#!/bin/bash
p="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
src=$1
dest=$2
echo "src:$src"
echo "dest:$dest"
expr="var src = \"$src\";var dest = \"$dest\";var colls = db.getSiblingDB(src).getCollectionNames();for (var i = 0; i < colls.length; i++) {var from = src + \".\" + colls[i];var to = dest + \".\" + colls[i];db.adminCommand({renameCollection: from, to: to});}"
echo "expr:$expr"
$p/prodmongodb_eval.sh "$expr"
#mongo -h dds-wz96c88b733b36d433330.mongodb.rds.aliyuncs.com -u  root -p nSSe4QRDPg4n  --port 3717 --authenticationDatabase admin --eval "var src = \"$src\";var dest = \"$dest\";var colls = db.getSiblingDB(from).getCollectionNames();for (var i = 0; i < colls.length; i++) {var from = src + "." + colls[i];var to = dest + "." + colls[i];db.adminCommand({renameCollection: from, to: to});}"
