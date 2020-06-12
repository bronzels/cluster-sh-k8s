kubectl get pvc -n md
#kubectl get pvc -n md|grep mdpostgre|awk '{print $1}'|xargs kubectl -n md delete pvc

helm install mdpostgre stable/postgresql -n md \
    --set postgresqlPassword=postgres \
    --set global.storageClass=rook-ceph-block \
    --set persistence.size=128Gi
#helm uninstall mdpostgre -n md
kubectl run mdpostgre-postgresql-client --rm --tty -i --restart='Never' --namespace md --image docker.io/bitnami/postgresql:11.7.0-debian-10-r9 --env="PGPASSWORD=postgres" --command -- \
  psql --host mdpostgre-postgresql -U postgres -d postgres -p 5432 \
  -c "SELECT version()"

kubectl get pod -n md
kubectl get svc -n md

:<<EOF
PostgreSQL can be accessed via port 5432 on the following DNS name from within your cluster:

    mdpostgre-postgresql.md.svc.cluster.local - Read/Write connection

To get the password for "postgres" run:

    export POSTGRES_PASSWORD=$(kubectl get secret --namespace md mdpostgre-postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)

To connect to your database run the following command:

    kubectl run mdpostgre-postgresql-client --rm --tty -i --restart='Never' --namespace md --image docker.io/bitnami/postgresql:11.7.0-debian-10-r9 --env="PGPASSWORD=$POSTGRES_PASSWORD" --command -- psql --host mdpostgre-postgresql -U postgres -d postgres -p 5432



To connect to your database from outside the cluster execute the following commands:

    kubectl port-forward --namespace md svc/mdpostgre-postgresql 5432:5432 &
    PGPASSWORD="$POSTGRES_PASSWORD" psql --host 127.0.0.1 -U postgres -d postgres -p 5432
EOF
