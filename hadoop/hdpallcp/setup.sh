
cd ~
MYHOME=~/hdpallcp

rm -rf ${MYHOME}
unzip /tmp/hdpallcp.zip

cp -r ${MYHOME} ${MYHOME}.bk

cd ${MYHOME}

chmod a+x resources/*.sh

file=values.yaml
cp ${file} ${file}.bk
sed -i 's@pullPolicy: IfNotPresent@pullPolicy: Always@g' ${file}

file=templates/statefulset-com.yaml
rm -f ${file}
cp statefulset.yaml.template ${file}
sed -i 's@<<subcp>>@com@g' ${file}

file=templates/statefulset-kylin.yaml
rm -f ${file}
cp statefulset.yaml.template ${file}
sed -i 's@<<subcp>>@kylin@g' ${file}

helm install mycp -n hadoop \
  --set conf.hiveConfigMap=myhv-hive \
  --set conf.hbaseConfigMap=hbase-configmap \
  --set conf.hadoopConfigMap=myhdp-hadoop \
  ./

:<<EOF
helm uninstall mycp -n hadoop

kubectl describe statefulset mycp-hdpallcp-kylin-server -n hadoop

kubectl get configmap mycp-hdpallcp -n hadoop -o yaml

kubectl get pod -n hadoop|grep mycp

kubectl describe pod mycp-hdpallcp-kylin-server-0 -n hadoop
kubectl logs mycp-hdpallcp-kylin-server-0 -n hadoop

kubectl exec -n hadoop -it mycp-hadoop-com-server-0 -- bash
kubectl exec -n hadoop -it mycp-hadoop-kylin-server-0 -- bash

kubectl describe pod -n hadoop mycp-kylin-server-0
kubectl logs mycp-kylin-server-0 -n hadoop
kubectl get pod -n hadoop | awk '{print $1}' | grep mycp-kylin-server-0 | xargs -I CNAME  sh -c "kubectl exec -n hadoop CNAME -- cat /usr/local/kylin/logs/kylin.log"

kubectl exec -it -n hadoop mmycp-kylin-server-0 -- bash

EOF
