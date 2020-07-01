#!/bin/bash

db=$1
echo "db:${db}"

kubectl run mdpostgre-postgresql-client --rm --tty -i --restart='Never' --namespace md --image docker.io/bitnami/postgresql:11.7.0-debian-10-r9 --env="PGPASSWORD=postgres" --command -- \
  psql --host mdpostgre-postgresql -d postgres -U postgres -p 5432 \
  -a -q -c "CREATE DATABASE ${db_name}"

kubectl --namespace md cp ~/scripts/t_trades_lvd.sql mdpostgre-postgresql-0:./
kubectl run mdpostgre-postgresql-client --rm --tty -i --restart='Never' --namespace md --image docker.io/bitnami/postgresql:11.7.0-debian-10-r9 --env="PGPASSWORD=postgres" --command -- \
  psql --host mdpostgre-postgresql -d "${db_name}" -U postgres -p 5432 \
  -a -q -f ./t_trades_lvd.sql
