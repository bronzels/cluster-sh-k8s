#!/bin/bash
catalog=$1
echo "catalog:${catalog}"
schema=$2
echo "schema:${schema}"

kubectl -n dw exec mypres-coordinator-??? -it -- presto --catalog ${catalog} --schema ${schema}
