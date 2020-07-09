#master01
#ubuntu

cd ~

sparkrev=2.4.6
hadooprev=2.7
wget -c https://downloads.apache.org/spark/spark-${sparkrev}/spark-${sparkrev}-bin-hadoop${hadooprev}.tgz
tar xzvf spark-${sparkrev}-bin-hadoop${hadooprev}.tgz
ln -s spark-${sparkrev}-bin-hadoop${hadooprev} spark

cd ~/spark

hadoopitrev=2.10.0
wget -c https://downloads.apache.org/hadoop/common/hadoop-${hadoopitrev}/hadoop-${hadoopitrev}.tar.gz
tar xzvf hadoop-${hadoopitrev}.tar.gz
hiveitrev=2.3.7
wget -c https://downloads.apache.org/hive/hive-${hiveitrev}/apache-hive-${hiveitrev}-bin.tar.gz
tar xzvf apache-hive-${hiveitrev}-bin.tar.gz

rm -rf hadoop-${hadoopitrev}/etc/hadoop
scp -r 10.10.1.62:/etc/hadoop/conf hadoop-${hadoopitrev}/etc/hadoop

rm -rf apache-hive-${hiveitrev}-bin/conf
scp -r 10.10.1.62:/opt/cloudera/parcels/CDH/lib/hive/conf apache-hive-${hiveitrev}-bin/conf

cp ~/k8sdeploy_dir/spark_shared_jars.tar.gz ./

MYHOME=~/spark/kubernetes/dockerfiles/spark
cp -rf ${MYHOME} ${MYHOME}.bk
cd ${MYHOME}

file=entrypoint.sh
cp ${MYHOME}.bk/${file} ${file}
sed -i '/# echo commands to the terminal output/a\echo \"10.10.9.83 master01\" >> /etc/hosts' ${file}
sed -i '/# echo commands to the terminal output/a\echo \"10.10.9.83 hk-prod-bigdata-master-7-44\" >> /etc/hosts' ${file}
sed -i '/# echo commands to the terminal output/a\echo \"10.10.1.62 hk-prod-bigdata-slave-0-234\" >> /etc/hosts' ${file}
sed -i '/# echo commands to the terminal output/a\echo \"10.10.10.34 hk-prod-bigdata-slave-10-34\" >> /etc/hosts' ${file}
sed -i '/# echo commands to the terminal output/a\echo \"10.10.3.233 hk-prod-bigdata-slave-3-233\" >> /etc/hosts' ${file}
sed -i '/# echo commands to the terminal output/a\echo \"10.10.5.226 hk-prod-bigdata-slave-5-226\" >> /etc/hosts' ${file}

file=Dockerfile
cp ${MYHOME}.bk/${file} ${file}
cat << EOF >> ${file}

COPY hadoop-${hadoopitrev} /opt/hadoop-${hadoopitrev}
RUN ln -s hadoop-${hadoopitrev} hadoop
COPY apache-hive-${hiveitrev}-bin /opt/apache-hive-${hiveitrev}-bin
RUN ln -s apache-hive-${hiveitrev}-bin hive
ADD spark_shared_jars.tar.gz /opt/spark/jars

ENV HADOOP_HOME /opt/hadoop
ENV HADOOP_CONF_DIR /opt/hadoop/etc/hadoop

ENV HCAT_HOME /opt/hive/hcatalog
ENV HIVE_HOME /opt/hive

EOF

cd ~/spark

docker images|grep "<none>"|awk '{print $3}'|xargs docker rmi -f

docker images|grep spark
docker images|grep spark|awk '{print $3}'|xargs docker rmi -f
ansible slavek8s -i /etc/ansible/hosts-ubuntu -m shell -a"docker images|grep spark|awk '{print \$3}'|xargs docker rmi -f"
docker images|grep spark

./bin/docker-image-tool.sh -r master01:30500/bronzels/spark -t 0.1 build
./bin/docker-image-tool.sh -r master01:30500/bronzels/spark -t 0.1 push

kubectl create serviceaccount spark
kubectl create clusterrolebinding spark-role-binding-spark --clusterrole=edit --serviceaccount=default:spark

#    --deploy-mode cluster \
#    local:///opt/spark/examples/jars/spark-examples_2.11-2.4.6.jar
bin/spark-submit \
    --master k8s://https://api.k8s.at.bronzels:6443 \
    --name spark-pi \
    --deploy-mode client \
    --class org.apache.spark.examples.SparkPi \
    --conf spark.executor.instances=3 \
    --conf spark.kubernetes.container.image=master01:30500/bronzels/spark:0.1 \
    --conf spark.kubernetes.authenticate.driver.serviceAccountName=spark \
    --conf spark.kubernetes.driver.limit.cores=2 \
    --conf spark.kubernetes.executor.limit.cores=8 \
    local://${HOME}/spark/examples/jars/spark-examples_2.11-2.4.6.jar

