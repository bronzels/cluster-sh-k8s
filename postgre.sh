helm install mdpostgre bitnami/postgresql -n md \
    --set service.type=NodePort \
    --set service.nodePort=31432 \
    --set postgresqlPassword=postgres \
    --set global.storageClass=rook-ceph-block \
    --set persistence.size=128Gi
:<<EOF
helm uninstall mdpostgre -n md
kubectl get pvc -n md|grep mdpostgre|awk '{print $1}'|xargs kubectl -n md delete pvc

#kubectl run mdpostgre-postgresql-client --rm --tty -i --restart='Never' --namespace md --image docker.io/bitnami/postgresql:11.7.0-debian-10-r9 --env="PGPASSWORD=postgres" --command -- \
#  psql --host mdpostgre-postgresql -U postgres -d postgres -p 5432 \
#  -c "SELECT version()"

kubectl run mdpostgre-postgresql-client --rm --tty -i --restart='Never' --namespace md --image docker.io/bitnami/postgresql:11.7.0-debian-10-r9 --env="PGPASSWORD=postgres" --command -- \
  psql --host 10.10.0.234 -U postgres -d postgres -p 31432 \
  -c "SELECT version()"

kubectl get pod -n md
kubectl get svc -n md
kubectl get pvc -n md
EOF

:<<EOF
NOTES:
** Please be patient while the chart is being deployed **

PostgreSQL can be accessed via port 5432 on the following DNS name from within your cluster:

    mdpostgre-postgresql.md.svc.cluster.local - Read/Write connection

To get the password for "postgres" run:

    export POSTGRES_PASSWORD=$(kubectl get secret --namespace md mdpostgre-postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)

To connect to your database run the following command:

    kubectl run mdpostgre-postgresql-client --rm --tty -i --restart='Never' --namespace md --image docker.io/bitnami/postgresql:11.8.0-debian-10-r33 --env="PGPASSWORD=$POSTGRES_PASSWORD" --command -- psql --host mdpostgre-postgresql -U postgres -d postgres -p 5432



To connect to your database from outside the cluster execute the following commands:

    export NODE_IP=$(kubectl get nodes --namespace md -o jsonpath="{.items[0].status.addresses[0].address}")
    export NODE_PORT=$(kubectl get --namespace md -o jsonpath="{.spec.ports[0].nodePort}" services mdpostgre-postgresql)
    PGPASSWORD="$POSTGRES_PASSWORD" psql --host $NODE_IP --port $NODE_PORT -U postgres -d postgres

EOF
