#!/bin/bash

catalog=$1
echo "catalog:${catalog}"
schema=$2
echo "schema:${schema}"

kubectl -n default run test-presto -ti --image=master01:30500/wiwdata/presto:0.1 --rm=true --restart=Never -- presto --server http://10.10.7.44:30080 --catalog ${catalog} --schema ${schema}
