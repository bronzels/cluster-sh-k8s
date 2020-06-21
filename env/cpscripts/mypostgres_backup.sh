#!/bin/bash
db=$1

kubectl run mdpostgre-postgresql-client --rm --tty -i --restart='Never' --namespace md --image docker.io/bitnami/postgresql:11.7.0-debian-10-r9 --env="PGPASSWORD=postgres" --command -- \
  psql --host mdpostgre-postgresql -U postgres -d postgres -p 5432 \
  -c "CREATE DATABASE ${db_name}"

kubectl -n {ns} exec -ti mdpostgre-postgresql-0 -- \
  mkdir ./${db}
kubectl -n {ns} exec -ti mdpostgre-postgresql-0 -- \
  pg_dump -h localhst -U postgres ${db} -t copytrading.t_trades_lvd > ./${db}/t_trades_lvd.sql
