#!/bin/bash

db_name=$1
echo "db_name:${db_name}"
schema_name=$2
echo "schema_name:${schema_name}"

. ${HOME}/scripts/k8s_funcs.sh

kubectl run -n md mdpostgre-postgresql-client --rm --tty -i --restart='Never' --image docker.io/bitnami/postgresql:11.7.0-debian-10-r9 --env="PGPASSWORD=postgres" --command -- \
  psql --host mdpostgre-postgresql -d postgres -U postgres -p 5432 \
  -a -q -c "DROP DATABASE IF EXISTS ${db_name}"
kubectl run -n md mdpostgre-postgresql-client --rm --tty -i --restart='Never' --image docker.io/bitnami/postgresql:11.7.0-debian-10-r9 --env="PGPASSWORD=postgres" --command -- \
  psql --host mdpostgre-postgresql -d postgres -U postgres -p 5432 \
  -a -q -c "CREATE DATABASE ${db_name}"
kubectl run -n md mdpostgre-postgresql-client --rm --tty -i --restart='Never' --image docker.io/bitnami/postgresql:11.7.0-debian-10-r9 --env="PGPASSWORD=postgres" --command -- \
  psql --host mdpostgre-postgresql -d postgres -U postgres -p 5432 \
  -a -q -c "select pg_database.datname, pg_size_pretty (pg_database_size(pg_database.datname)) AS size from pg_database"

#kubectl cp ~/scripts/t_trades_lvd.sql md/mdpostgre-postgresql-0:/opt/bitnami/scripts/postgresql/

kubectl run -n md mdpostgre-postgresql-client --restart='Never' --image docker.io/bitnami/postgresql:11.7.0-debian-10-r9 --overrides="$(cat ${HOME}/mypostgre/mdpostgre-postgresql-client.yaml | y2j)"
wait_pod_running "md" "mdpostgre-postgresql-client" 1 600
kubectl exec -it -n md mdpostgre-postgresql-client -- \
  ls -l /opt/bitnami/postgresql/com/postgres/t_trades_lvd.sql
kubectl exec -it -n md mdpostgre-postgresql-client -- \
  psql --host mdpostgre-postgresql -d "${db_name}" -U postgres -p 5432 \
  -a -q -f /opt/bitnami/postgresql/com/postgres/t_trades_lvd.sql
kubectl delete pod -n md mdpostgre-postgresql-client
wait_pod_deleted "md" "mdpostgre-postgresql-client" 600

kubectl run -n md mdpostgre-postgresql-client --rm --tty -i --restart='Never' --image docker.io/bitnami/postgresql:11.7.0-debian-10-r9 --env="PGPASSWORD=postgres" --command -- \
  psql --host mdpostgre-postgresql -d bd_2_2_4_0_0 -U postgres -p 5432 \
  -a -q -c "select tablename from pg_tables where schemaname='${schema_name}'"

