#!/bin/bash

db_name=$1
echo "db_name:${db_name}"
schema_name=$2
echo "schema_name:${schema_name}"
table_name=$3
echo "table_name:${table_name}"

kubectl run mdpostgre-postgresql-client --rm --tty -i --restart='Never' --namespace md --image docker.io/bitnami/postgresql:11.7.0-debian-10-r9 --env="PGPASSWORD=postgres" --command -- \
  psql --host mdpostgre-postgresql -d ${db_name} -U postgres -p 5432 \
  -a -q -c "drop table ${schema_name}.${table_name}"
