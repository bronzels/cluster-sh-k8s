#!/bin/bash
p="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
src=$1
dest=$2
echo "src:$src"
echo "dest:$dest"
expr="var src = \"$src\";var dest = \"$dest\";var colls = db.getSiblingDB(src).getCollectionNames();for (var i = 0; i < colls.length; i++) {var from = src + \".\" + colls[i];var to = dest + \".\" + colls[i];db.adminCommand({renameCollection: from, to: to});}"
echo "expr:$expr"
$p/mymongodb_eval.sh "$expr"
