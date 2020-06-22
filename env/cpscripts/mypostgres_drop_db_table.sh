db_name=$1
schema_name=$2
table_name=$3

kubectl run mdpostgre-postgresql-client --rm --tty -i --restart='Never' --namespace md --image docker.io/bitnami/postgresql:11.7.0-debian-10-r9 --env="PGPASSWORD=postgres" --command -- \
  psql --host mdpostgre-postgresql -d ${db_name} -U postgres -p 5432 \
  -a -q -c "drop table ${schema_name}.${table_name}"
