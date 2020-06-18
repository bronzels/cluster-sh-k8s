
cd ~
MYHOME=~/hdpallcp

rm -rf ${MYHOME}
unzip /tmp/hdpallcp.zip

cp -r ${MYHOME} ${MYHOME}.bk

cd ${MYHOME}

./image/hdpallcp.sh
#./image/hdpallcpcom.sh
./image/hdpallcpkylin.sh

chmod a+x resources/*.sh

file=values.yaml
cp ${file} ${file}.bk
sed -i 's@pullPolicy: IfNotPresent@pullPolicy: Always@g' ${file}

:<<EOF
file=templates/statefulset-com.yaml
rm -f ${file}
cp statefulset.yaml.template ${file}
sed -i 's@<<subcp>>@com@g' ${file}

file=templates/svc-ssh-com.yaml
rm -f ${file}
cp svc-ssh.yaml.template ${file}
sed -i 's@<<subcp>>@com@g' ${file}
EOF

file=templates/statefulset-kylin.yaml
rm -f ${file}
cp statefulset.yaml.template ${file}
sed -i 's@<<subcp>>@kylin@g' ${file}

file=templates/svc-ssh-kylin.yaml
rm -f ${file}
cp svc-ssh.yaml.template ${file}
sed -i 's@<<subcp>>@kylin@g' ${file}

helm uninstall mycp -n hadoop
kubectl exec -n hadoop -it myhdp-hadoop-hdfs-nn-0 -- /usr/local/hadoop/bin/hdfs dfs -rm -r -f /kylin
kubectl exec myzk-zookeeper-0 -n hadoop -- bin/zkCli.sh deleteall /kylin

cat << \EOF > dropmeta.cmd
disable 'kylin_metadata'
drop 'kylin_metadata'
EOF

helm install mycp -n hadoop \
  --set conf.hiveConfigMap=myhv-hive \
  --set conf.hbaseConfigMap=hbase-configmap \
  --set conf.hadoopConfigMap=myhdp-hadoop \
  ./

:<<EOF
kubectl get pod -n hadoop|grep mycp
kubectl get svc -n hadoop|grep mycp

kubectl exec -n hadoop -it mycp-hdpallcp-kylin-server-0 -- bash

kubectl exec -n hadoop -it myhdp-hadoop-hdfs-nn-0 -- /usr/local/hadoop/bin/hdfs dfs -ls /kylin
kubectl exec myzk-zookeeper-0 -n hadoop -- bin/zkCli.sh ls /kylin

kubectl exec -it myhb-hbase-master-0 -n hadoop -- bash
  cat dropmeta.cmd | bin/hbase shell -n

kubectl exec -n hadoop -it mycp-hdpallcp-com-server-0 -- bash

kubectl describe statefulset mycp-hdpallcp-kylin-server -n hadoop

kubectl get configmap mycp-hdpallcp -n hadoop -o yaml

kubectl describe pod mycp-hdpallcp-kylin-server-0 -n hadoop
kubectl logs mycp-hdpallcp-kylin-server-0 -n hadoop


kubectl describe pod -n hadoop mycp-kylin-server-0
kubectl logs mycp-kylin-server-0 -n hadoop
kubectl get pod -n hadoop | awk '{print $1}' | grep mycp-kylin-server-0 | xargs -I CNAME  sh -c "kubectl exec -n hadoop CNAME -- cat /usr/local/kylin/logs/kylin.log"

kubectl exec -it -n hadoop mmycp-kylin-server-0 -- bash

EOF
