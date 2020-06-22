#!/bin/bash
prefix=$1

kubectl -n md exec -ti mdpostgre-postgresql-0 -- \
  psql -h localhst -U postgres -d "${prefix}" -f ./"${prefix}"/t_trades_lvd.sql
