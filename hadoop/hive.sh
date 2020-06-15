cd ~
git clone https://github.com/Gradiant/charts.git gradiant
#MYHOME=~/gradiant/charts/hive
MYHOME=~/gradiant/charts/hive-metastore
cp -r ${MYHOME} ${MYHOME}.bk
cd ${MYHOME}

helm repo add gradiant https://gradiant.github.io/charts/
  #gradiant/hive --version 0.1.3
helm install myhv -n hadoop \
  --set conf.hadoopConfigMap=myhdp-hadoop \
  --set hdfs.enabled=false \
  gradiant/hive-metastore --version 0.1.1
:<<EOF
helm uninstall myhv -n hadoop
kubectl get pvc -n hadoop | awk '{print $1}' | grep data-myhv | xargs kubectl delete pvc -n hadoop
kubectl get pod -n hadoop|grep myhv
kubectl describe pod -n hadoop myhv-hive-server-0
EOF
helm repo delete gradiant