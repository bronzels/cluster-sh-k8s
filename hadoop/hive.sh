cd ~

git clone https://github.com/Gradiant/charts.git gradiant
MYHOME=~/gradiant/charts/hive
#MYHOME=~/gradiant/charts/hive-metastore
cp -r ${MYHOME} ${MYHOME}.bk

git clone https://github.com/big-data-europe/docker-hive.git
MYIMGHOME=~/gradiant/charts/hive/docker-hive
cp -r ${MYIMGHOME} ${MYIMGHOME}.bk
cd ${MYIMGHOME}

docker images|grep hive
docker images|grep hive|awk '{print $3}'|xargs docker rmi -f
ansible slave -m shell -a"docker images|grep hive|awk '{print \$3}'|xargs docker rmi -f"
docker images|grep hive

file=Dockerfile
cp ${MYIMGHOME}.bk/$file $file
sed -i 's@FROM bde2020\/hadoop-base:2.0.0-hadoop2.7.4-java8@FROM bde2020\/hadoop-base:latest@g' ${file}
sed -i 's@ENV HIVE_VERSION=${HIVE_VERSION:-2.3.2}@ENV HIVE_VERSION=${HIVE_VERSION:-3.1.2}@g' ${file}
sed -i 's@ENTRYPOINT@#ENTRYPOINT@g' ${file}
sed -i 's@CMD startup.sh@#CMD startup.sh@g' ${file}
docker build -t master01:30500/bde2020/hive:2.3.2-postgresql-metastore ./
docker push master01:30500/bde2020/hive:2.3.2-postgresql-metastore
docker images|grep hive

cd ${MYHOME}

#file=templates/configmap.yaml
#cp ${MYHOME}.bk/${file} ${file}
#sed -i '/    <\/configuration>/i\        <property>\n            <name>hive.server2.thrift.bind.host<\/name>\n            <value>0.0.0.0<\/value>\n            <description>Bind host on which to run the HiveServer2 Thrift interface.\n                Can be overridden by setting <\/description>\n        <\/property>\n        <property>\n            <name>hive.server2.thrift.port<\/name>\n            <value>9084<\/value>\n        <\/property>\n        <property>\n            <name>hive.server2.thrift.http.port<\/name>\n            <value>9085<\/value>\n        <\/property>' ${file}

groupadd supergroup
usermod -a -G supergroup hive
su - hive -s /bin/bash -c "hdfs dfsadmin -refreshUserToGroupsMappings"

#  --set conf.hiveSite."hive\.server2\.thrift\.port"=9084 \
#  --set conf.hiveSite."hive\.server2\.thrift\.http\.port"=9085 \
helm repo add gradiant https://gradiant.github.io/charts/

:<<EOF
helm install myhv -n hadoop \
  --set image.repository=master01:30500/bde2020/hive \
  gradiant/hive-metastore --version 0.1.1
#  ./
EOF

#  --set image.repository=master01:30500/bde2020/hive \
helm install myhv -n hadoop \
  --set metastore.enabled=true \
  --set hdfs.enabled=false \
  --set conf.hadoopConfigMap=myhdp-hadoop \
  --set conf.hdfsAdminUser=root \
  gradiant/hive --version 0.1.3
#  ./
# 	--set conf.hiveSite."hive\.server2\.thrift\.bind\.host"="0.0.0.0" \
#  --set conf.hiveSite."hive\.server2\.thrift\.port"=10000 \
#  --set conf.hiveSite."hive\.server2\.thrift\.http\.port"=10002 \

helm repo delete gradiant

:<<EOF
helm uninstall myhv -n hadoop
kubectl get pvc -n hadoop | awk '{print $1}' | grep data-myhv | xargs kubectl delete pvc -n hadoop
kubectl exec -n hadoop -it myhdp-hadoop-hdfs-nn-0 -- /usr/local/hadoop/bin/hdfs dfs -rm -r -f /user
kubectl exec -n hadoop -it myhdp-hadoop-hdfs-nn-0 -- /usr/local/hadoop/bin/hdfs dfs -rm -r -f /tmp/hive

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
cat << EOF > student.txt
2 "trump"
3 "wyh"
EOF
cat << EOF > student.txt
2,"trump"
3,"wyh"
EOF
cat student.txt
