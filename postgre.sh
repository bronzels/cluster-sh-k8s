
helm install mdpostgre bitnami/postgresql -n md \
    --set service.type=NodePort \
    --set service.nodePort=31432 \
    --set postgresqlPassword=postgres \
    --set global.storageClass=rook-ceph-block \
    --set persistence.size=128Gi

mkdir ~/mypostgre
cd ~/mypostgre

mkdir ~/nfsmnt/postgres
#！！！把项目工程postgresql初始化的sql脚本（～/scripts下）copy到以上目录中

kubectl delete -f mdpostgre-nfs-pvc.yaml -n md
cat << \EOF > mdpostgre-nfs-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mdpostgre-nfs-pvc
  labels:
    storage: mdpostgre-nfs-pvc
  annotations:
    kubernetes.io/description: "PersistentVolumeClaim for PV"
spec:
  selector:
    matchLabels:
      storage: mdpostgre-nfs-pv
  accessModes:
    - ReadWriteMany
  volumeMode: Filesystem
  storageClassName: nfs
  resources:
    requests:
      storage: 1Gi
EOF
kubectl apply -f mdpostgre-nfs-pvc.yaml -n md
kubectl get pvc -n md

kubectl delete -f mdpostgre-nfs-pv.yaml
cat << \EOF > mdpostgre-nfs-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mdpostgre-nfs-pv
  labels:
    storage: mdpostgre-nfs-pv
  annotations:
    kubernetes.io.description: pv-storage
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  storageClassName: nfs
  mountOptions:
    - vers=4
    - port=2149
  nfs:
    path: /
    server: 1110.1110.9.83
EOF
kubectl apply -f mdpostgre-nfs-pv.yaml
kubectl get pv|grep mdpostgre-nfs-pv

#    command: ["sleep", "60000"]
cat << \EOF > mdpostgre-postgresql-client.yaml
apiVersion: v1
kind: Pod
metadata:
  name: mdpostgre-postgresql-client
spec:
  restartPolicy: Never
  containers:
  - name: mdpostgre-postgresql-client
    image: docker.io/bitnami/postgresql:11.7.0-debian-10-r9
    volumeMounts:
    - name: mdpostgre-postgresql-client-pv1
      mountPath: /opt/bitnami/postgresql/com
    env:
    - name: POSTGRESQL_PASSWORD
      value: "postgres"
    - name: PGPASSWORD
      value: "postgres"
  volumes:
  - name: mdpostgre-postgresql-client-pv1
    persistentVolumeClaim:
      claimName: mdpostgre-nfs-pvc
EOF

:<<EOF
helm uninstall mdpostgre -n md
kubectl get pvc -n md|grep mdpostgre|awk '{print $1}'|xargs kubectl -n md delete pvc

kubectl run mdpostgre-postgresql-client --rm --tty -i --restart='Never' --namespace md --image docker.io/bitnami/postgresql:11.7.0-debian-10-r9 --env="PGPASSWORD=postgres" --command -- \
  psql --host mdpostgre-postgresql -U postgres -d postgres -p 5432 \
  -c "SELECT version()"

kubectl run mdpostgre-postgresql-client --rm --tty -i --restart='Never' --namespace md --image docker.io/bitnami/postgresql:11.7.0-debian-10-r9 --env="PGPASSWORD=postgres" --command -- \
  psql --host 1110.1110.1.62 -U postgres -d postgres -p 31432 \
  -c "SELECT version()"

kubectl get pod -n md
kubectl get svc -n md
kubectl get pvc -n md

kubectl exec -n md -t `kubectl get pod -n md | grep mdpostgre-postgresql | awk '{print $1}'`  -- /bin/sh

EOF

:<<EOF
NOTES:
** Please be patient while the chart is being deployed **

PostgreSQL can be accessed via port 5432 on the following DNS name from within your cluster:

    mdpostgre-postgresql.md.svc.cluster.local - Read/Write connection

To get the password for "postgres" run:

    export POSTGRES_PASSWORD=$(kubectl get secret --namespace md mdpostgre-postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)

To connect to your database run the following command:

    kubectl run mdpostgre-postgresql-client --rm --tty -i --restart='Never' --namespace md --image docker.io/bitnami/postgresql:11.8.0-debian-10-r51 --env="PGPASSWORD=$POSTGRES_PASSWORD" --command -- psql --host mdpostgre-postgresql -U postgres -d postgres -p 5432



To connect to your database from outside the cluster execute the following commands:

    export NODE_IP=$(kubectl get nodes --namespace md -o jsonpath="{.items[0].status.addresses[0].address}")
    export NODE_PORT=$(kubectl get --namespace md -o jsonpath="{.spec.ports[0].nodePort}" services mdpostgre-postgresql)
    PGPASSWORD="$POSTGRES_PASSWORD" psql --host $NODE_IP --port $NODE_PORT -U postgres -d postgres
EOF
