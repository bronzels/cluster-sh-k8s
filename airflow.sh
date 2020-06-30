
rm -rf ${HOME}/nfsmnt/dags
cp -rf ~/k8sdeploy_dir/dags ${HOME}/nfsmnt/

mkdir ~/myairflow
cd ~/myairflow

docker stop `docker ps | grep mynfs-af | awk '{print $1}'`
docker rm `docker ps -a | grep mynfs-af | awk '{print $1}'`
docker run -d -p 2149:2049 --name mynfs-af --privileged -v ${HOME}/nfsmnt:/nfsshare -e SHARED_DIRECTORY=/nfsshare itsthenetwork/nfs-server-alpine:latest
sudo netstat -nlap|grep 2149
mkdir testafmnt
sudo mount -v -o vers=4,loud,port=2149 10.10.7.44:/ testafmnt
#sudo mount -v -o vers=4,loud 10.10.7.44:/ testafmnt
ls testafmnt
sudo umount testafmnt

kubectl delete -f myaf-nfs-pv.yaml
cat << \EOF > myaf-nfs-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: myaf-nfs-pv
  labels:
    storage: myaf-nfs-pv
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
    server: 10.10.7.44
EOF
kubectl apply -f myaf-nfs-pv.yaml
kubectl get pv|grep myaf-nfs-pv
kubectl get pvc -n fl

kubectl delete -f myaf-nfs-pvc.yaml -n fl
cat << \EOF > myaf-nfs-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myaf-nfs-pvc
  labels:
    storage: myaf-nfs-pvc
  annotations:
    kubernetes.io/description: "PersistentVolumeClaim for PV"
spec:
  accessModes:
    - ReadWriteMany
  volumeMode: Filesystem
  storageClassName: nfs
  resources:
    requests:
      storage: 1Gi
EOF
kubectl apply -f myaf-nfs-pvc.yaml -n fl
kubectl get pvc -n fl
:<<EOF
  selector:
    matchLabels:
      storage: myaf-nfs-pv
EOF

cat << EOF > busy-box-test1.yaml
apiVersion: v1
kind: Pod
metadata:
  name: busy-box-test1
spec:
  restartPolicy: OnFailure
  containers:
  - name: busy-box-test1
    image: busybox
    volumeMounts:
    - name: busy-box-test-pv1
      mountPath: /mnt/busy-box
    command: ["sleep", "60000"]
  volumes:
  - name: busy-box-test-pv1
    persistentVolumeClaim:
      claimName: myaf-nfs-pvc
EOF
kubectl create -f busy-box-test1.yaml -n fl
. ${HOME}/scripts/k8s_funcs.sh
wait_pod_running "fl" "busy-box-test1" 1 600
#kubectl delete -f busy-box-test1.yaml
kubectl exec -it busy-box-test1 -n fl -- ls /mnt/busy-box/dags
kubectl delete pod busy-box-test1 -n fl
#wait_pod_deleted "fl" "busy-box-test1" 600

file=Dockerfile
cat << \EOF > ${file}
FROM apache/airflow:1.10.10-python3.6
MAINTAINER bronzels@hotmail.com

USER root:root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
           libsasl2-dev \
           libmysqld-dev \
           build-essential \
    && apt-get autoremove -yqq --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER ${AIRFLOW_UID}

EOF

docker images|grep "<none>"|awk '{print $3}'|xargs docker rmi -f

docker images|grep airflow
docker images|grep airflow|awk '{print $3}'|xargs docker rmi -f
sudo ansible slavek8s -m shell -a"docker images|grep airflow|awk '{print \$3}'|xargs docker rmi -f"
docker images|grep airflow

docker build -t master01:30500/bronzels/airflow:1.10.10-python3.6 ./
docker push master01:30500/bronzels/airflow:1.10.10-python3.6

file=~/scripts/myairflow-cp-op.sh
rm -f ${file}
cat << \EOF > ${file}
#!/bin/bash

. ${HOME}/scripts/k8s_funcs.sh

cd ~/myairflow

#set -e

if [ $1 == "stop" -o $1 == "restart" ]; then
  helm delete myaf -n fl
  wait_pod_deleted "fl" "myaf-" 600
fi

if [ $1 == "start" -o $1 == "restart" ]; then
  helm install myaf -n fl \
    --set airflow.config.AIRFLOW__SMTP__SMTP_HOST="smtp.exmail.qq.com" \
    --set airflow.config.AIRFLOW__SMTP__SMTP_STARTTLS="False" \
    --set airflow.config.AIRFLOW__SMTP__SMTP_SSL="True" \
    --set airflow.config.AIRFLOW__SMTP__SMTP_PORT="465" \
    --set airflow.config.AIRFLOW__SMTP__SMTP_USER="big-data@followme.cn" \
    --set airflow.config.AIRFLOW__SMTP__SMTP_PASSWORD="sf323mNoK" \
    --set airflow.config.AIRFLOW__SMTP__SMTP_MAIL_FROM="big-data@followme.cn" \
    --set airflow.config.AIRFLOW__CORE__LOAD_EXAMPLES="False" \
    --set dags.installRequirements=true \
    --set dags.persistence.enabled=true\
    --set dags.persistence.existingClaim="myaf-nfs-pvc" \
    --set dags.persistence.subPath="dags" \
    --set airflow.image.repository="master01:30500/bronzels/airflow" \
    --set airflow.image.tag="1.10.10-python3.6" \
    stable/airflow
  wait_pod_running "fl" "myaf-" 6 600
  wait_pod_log_line "fl" "myaf-scheduler" "INFO - Creating tables" 900
  wait_pod_log_line "fl" "myaf-worker" "*** running scheduler..." 900
  wait_pod_log_line "fl" "myaf-web" "*** running webserver..." 900
fi
EOF
chmod a+x ${file}

~/scripts/myairflow-cp-op.sh start
~/scripts/myairflow-cp-op.sh stop
~/scripts/myairflow-cp-op.sh restart

:<<EOF
kubectl get pod -n fl
kubectl get svc -n fl


kubectl logs `kubectl get pod -n fl | grep myaf-scheduler | awk '{print $1}'` -n fl
kubectl logs `kubectl get pod -n fl | grep myaf-worker | awk '{print $1}'` -n fl
kubectl logs `kubectl get pod -n fl | grep myaf-web | awk '{print $1}'` -n fl

kubectl exec -it `kubectl get pod -n fl | grep myaf-scheduler | awk '{print $1}'` -n fl -- ls /opt/airflow/dags
kubectl exec -it `kubectl get pod -n fl | grep myaf-worker | awk '{print $1}'` -n fl -- ls /opt/airflow/dags
kubectl exec -n fl -t `kubectl get pod -n fl | grep myaf-web | awk '{print $1}'`  -- ls /opt/airflow/dags

kubectl exec -n fl -t `kubectl get pod -n fl | grep myaf-web | awk '{print $1}'`  -- python -V
#Python 3.6.10

NOTES:
Congratulations. You have just deployed Apache Airflow!

1. Get the Airflow Service URL by running these commands:
   export POD_NAME=$(kubectl get pods --namespace fl -l "component=web,app=airflow" -o jsonpath="{.items[0].metadata.name}")
   echo http://127.0.0.1:8080
   kubectl port-forward --namespace fl $POD_NAME 8080:8080

2. Open Airflow in your web browser
EOF
