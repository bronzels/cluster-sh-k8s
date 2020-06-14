#HDPHOME=~/charts/stable/hadoop
HDPHOME=~/helm-hadoop-3
cd ${HDPHOME}

#chmod a+x tools/calc_resources.sh
#helm install myhadoop $(tools/calc_resources.sh 50) -n hadoop -f values.yaml \
helm install myhdp -n hadoop -f values.yaml \
  --set hdfs.dataNode.replicas=4 \
  --set yarn.nodeManager.replicas=4 \
  --set persistence.nameNode.enabled=true \
  --set persistence.nameNode.storageClass=rook-ceph-block \
  --set persistence.dataNode.enabled=true \
  --set persistence.dataNode.storageClass=rook-ceph-block \
  --set persistence.nameNode.size=128Gi \
  --set persistence.dataNode.size=1024Gi \
  --set hdfs.dataNode.resources.requests.memory="4096Mi" \
  --set hdfs.dataNode.resources.requests.cpu="2000m" \
  --set hdfs.dataNode.resources.limits.memory="8196Mi" \
  --set hdfs.dataNode.resources.limits.cpu="4000m" \
  --set yarn.nodeManager.resources.requests.memory="16384Mi" \
  --set yarn.nodeManager.resources.requests.cpu="4000m" \
  --set yarn.nodeManager.resources.limits.memory="65536Mi" \
  --set yarn.nodeManager.resources.limits.cpu="14000m" \
  ./

:<<EOF
helm uninstall myhdp -n hadoop
kubectl get pvc -n hadoop | awk '{print $1}' | grep dfs-myhdp | xargs kubectl delete pvc -n hadoop

kubectl describe pod myhdp-hadoop-hdfs-dn-1 -n hadoop
kubectl describe pod myhdp-hadoop-yarn-nm-0 -n hadoop
kubectl exec -it myhdp-hadoop-yarn-rm-0 -n hadoop bash

kubectl get pod -n hadoop -o wide
kubectl get pvc -n hadoop -o wide
kubectl get svc -n hadoop -o wide

kubectl exec -n hadoop -it myhdp-hadoop-hdfs-nn-0 -- /usr/local/hadoop/bin/hdfs dfs -ls /
yarn: http://master01:31088/cluster
hdfs: http://master01:30870/dfshealth.html#tab-overview

EOF

:<<EOF
NOTES:
1. You can check the status of HDFS by running this command:
   kubectl exec -n hadoop -it myhdp-hadoop-hdfs-nn-0 -- /usr/local/hadoop/bin/hdfs dfsadmin -report

2. You can list the yarn nodes by running this command:
   kubectl exec -n hadoop -it myhdp-hadoop-yarn-rm-0 -- /usr/local/hadoop/bin/yarn node -list

3. Create a port-forward to the yarn resource manager UI:
   kubectl port-forward -n hadoop myhdp-hadoop-yarn-rm-0 8088:8088

   Then open the ui in your browser:

   open http://localhost:8088

4. You can run included hadoop tests like this:
   kubectl exec -n hadoop -it myhdp-hadoop-yarn-nm-0 -- /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-2.9.0-tests.jar TestDFSIO -write -nrFiles 5 -fileSize 128MB -resFile /tmp/TestDFSIOwrite.txt

5. You can list the mapreduce jobs like this:
   kubectl exec -n hadoop -it myhdp-hadoop-yarn-rm-0 -- /usr/local/hadoop/bin/mapred job -list

6. This chart can also be used with the zeppelin chart
    helm install --namespace hadoop --set hadoop.useConfigMap=true,hadoop.configMapName=myhdp-hadoop stable/zeppelin

7. You can scale the number of yarn nodes like this:
   helm upgrade myhdp --set yarn.nodeManager.replicas=4 stable/hadoop

   Make sure to update the values.yaml if you want to make this permanent.
EOF

:<<EOF
NOTES:
1. You can check the status of HDFS by running this command:
   kubectl exec -n hadoop -it myhdp-hadoop-hdfs-nn-0 -- /usr/local/hadoop/bin/hdfs dfsadmin -report

2. You can list the yarn nodes by running this command:
   kubectl exec -n hadoop -it myhdp-hadoop-yarn-rm-0 -- /usr/local/hadoop/bin/yarn node -list

3. Create a port-forward to the yarn resource manager UI:
   #kubectl port-forward -n hadoop myhdp-hadoop-yarn-rm-0 8088:8088

   Then open the ui in your browser:

   #open http://localhost:8088

4. You can run included hadoop tests like this:
   kubectl exec -n hadoop -it myhdp-hadoop-yarn-nm-0 -- /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-3.2.1-tests.jar TestDFSIO -write -nrFiles 5 -fileSize 128MB -resFile /tmp/TestDFSIOwrite.txt

5. You can list the mapreduce jobs like this:
   kubectl exec -n hadoop -it myhdp-hadoop-yarn-rm-0 -- /usr/local/hadoop/bin/mapred job -list

6. This chart can also be used with the zeppelin chart
    helm install --namespace hadoop --set hadoop.useConfigMap=true,hadoop.configMapName=myhdp-hadoop stable/zeppelin

7. You can scale the number of yarn nodes like this:
   helm upgrade myhdp --set yarn.nodeManager.replicas=4 stable/hadoop

   Make sure to update the values.yaml if you want to make this permanent.
EOF

:<<EOF
NOTES:
1. You can check the status of HDFS by running this command:
   kubectl exec -n hadoop -it myhdp-hadoop-hdfs-nn-0 -- /usr/local/hadoop/bin/hdfs dfsadmin -report

2. You can list the yarn nodes by running this command:
   kubectl exec -n hadoop -it myhdp-hadoop-yarn-rm-0 -- /usr/local/hadoop/bin/yarn node -list

3. Create a port-forward to the yarn resource manager UI:
   kubectl port-forward -n hadoop myhdp-hadoop-yarn-rm-0 8088:8088

   Then open the ui in your browser:

   open http://localhost:8088

4. You can run included hadoop tests like this:
   kubectl exec -n hadoop -it myhdp-hadoop-yarn-nm-0 -- /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-3.1.1-tests.jar TestDFSIO -write -nrFiles 5 -fileSize 128MB -resFile /tmp/TestDFSIOwrite.txt

5. You can list the mapreduce jobs like this:
   kubectl exec -n hadoop -it myhdp-hadoop-yarn-rm-0 -- /usr/local/hadoop/bin/mapred job -list

6. This chart can also be used with the zeppelin chart
    helm install --namespace hadoop --set hadoop.useConfigMap=true,hadoop.configMapName=myhdp-hadoop stable/zeppelin

7. You can scale the number of yarn nodes like this:
   helm upgrade myhdp --set yarn.nodeManager.replicas=4 stable/hadoop

   Make sure to update the values.yaml if you want to make this permanent.
EOF
