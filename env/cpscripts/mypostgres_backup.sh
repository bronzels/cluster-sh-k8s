#!/bin/bash
db=$1

kubectl -n md exec -ti mdpostgre-postgresql-0 -- \
  mkdir ./${db}
kubectl -n md exec -ti mdpostgre-postgresql-0 -- \
  pg_dump -h localhost -U postgres ${db} -t copytrading.t_trades_lvd > ./${db}/t_trades_lvd.sql
