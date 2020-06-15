cd ~
git clone https://github.com/Gradiant/charts.git gradiant
#MYHOME=~/gradiant/charts/hive
MYHOME=~/gradiant/charts/hive-metastore
cp -r ${MYHOME} ${MYHOME}.bk
cd ${MYHOME}

#file=templates/configmap.yaml
#cp ${MYHOME}.bk/${file} ${file}
#sed -i '/    <\/configuration>/i\        <property>\n            <name>hive.server2.thrift.bind.host<\/name>\n            <value>0.0.0.0<\/value>\n            <description>Bind host on which to run the HiveServer2 Thrift interface.\n                Can be overridden by setting <\/description>\n        <\/property>\n        <property>\n            <name>hive.server2.thrift.port<\/name>\n            <value>9084<\/value>\n        <\/property>\n        <property>\n            <name>hive.server2.thrift.http.port<\/name>\n            <value>9085<\/value>\n        <\/property>' ${file}

helm repo add gradiant https://gradiant.github.io/charts/
  #gradiant/hive --version 0.1.3
helm install myhv -n hadoop \
  --set conf.hadoopConfigMap=myhdp-hadoop \
  --set hdfs.enabled=false \
	--set conf.hiveSite."hive\.server2\.thrift\.bind\.host"="0.0.0.0" \
	--set conf.hiveSite."hive\.server2\.thrift\.port"=9084 \
	--set conf.hiveSite."hive\.server2\.thrift\.http\.port"=9085 \
  gradiant/hive-metastore --version 0.1.1
#  ./
:<<EOF
helm uninstall myhv -n hadoop
kubectl get configmap myhv-hive-metastore -n hadoop -o yaml
kubectl get pvc -n hadoop | awk '{print $1}' | grep data-myhv | xargs kubectl delete pvc -n hadoop
kubectl get pod -n hadoop|grep myhv
kubectl describe pod -n hadoop myhv-hive-server-0
EOF
helm repo delete gradiant