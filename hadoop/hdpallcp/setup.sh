
cd ~

unzip /tmp/hdpallcp.zip
cp -r hdpallcp hdpallcp.bk

cd ~/hdpallcp

file=values.yaml
cp ${file} ${file}.bk
sed -i 'pullPolicy: IfNotPresent@pullPolicy: Always@g' ${file}

file=statefulset-com.yaml
rm -f templates/${file}
cp templates/statefulset.yaml.template templates/${file}
sed -i 's@<<subcp>>@com@g' ${file}

file=statefulset-kylin.yaml
rm -f templates/${file}
cp templates/statefulset.yaml.template templates/${file}
sed -i 's@<<subcp>>@kylin@g' ${file}

helm install mycp -n hadoop \
  --set conf.hadoopConfigMap=myhv-hive \
  --set conf.hadoopConfigMap=hbase-configmap \
  --set conf.hadoopConfigMap=myhdp-hadoop \
  ./

:<<EOF
helm uninstall mycp -n hadoop
kubectl exec -n hadoop -it mycp-hadoop-com-server-0 -- bash
kubectl exec -n hadoop -it mycp-hadoop-kylin-server-0 -- bash

kubectl get configmap -n hadoop | grep myhv
kubectl get configmap myhv-hive -n hadoop -o yaml
kubectl get configmap myhv-metastore -n hadoop -o yaml

kubectl get pod -n hadoop|grep myhv

kubectl describe pod -n hadoop myhv-hive-server-0
kubectl get pod -n hadoop | awk '{print $1}' | grep myhv-hive-server-0 | xargs -I CNAME  sh -c "kubectl exec -n hadoop CNAME -- ls /tmp/root"

kubectl exec -n hadoop -it myhdp-hadoop-hdfs-nn-0 -- /usr/local/hadoop/bin/hdfs dfs -ls /
kubectl exec -n hadoop -it myhdp-hadoop-hdfs-nn-0 -- /usr/local/hadoop/bin/hdfs dfs -ls /user
kubectl exec -n hadoop -it myhdp-hadoop-hdfs-nn-0 -- /usr/local/hadoop/bin/hdfs dfs -ls /user/hive
kubectl exec -n hadoop -it myhdp-hadoop-hdfs-nn-0 -- /usr/local/hadoop/bin/hdfs dfs -ls /user/hive/warehouse

kubectl exec -it -n hadoop myhv-metastore-0 -- bash
#CREATE TABLE IF NOT EXISTS students(id INT,name STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY "\t";
kubectl exec -it -n hadoop myhv-hive-server-0 -- bash
  hive/bin/hive
    DROP TABLE IF EXISTS students;
    CREATE TABLE IF NOT EXISTS students(id INT,name STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY ",";
    LOAD DATA LOCAL INPATH '/opt/student.txt' INTO TABLE students;
    SELECT * FROM students;

EOF
