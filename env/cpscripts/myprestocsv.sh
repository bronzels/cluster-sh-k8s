#!/bin/bash
sql=$1
output=$2
echo "sql:$sql"
echo "output:$output"
~/presto-server/bin/presto-cli --server http://pro-hbase01:8070 --catalog hive --schema default --execute ''$sql'' --output-format CSV_HEADER > "$output".csv
