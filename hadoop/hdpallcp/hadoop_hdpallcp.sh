cd ~
MYHOME=~/hdpallcp
rm -rf ${MYHOME}

unzip hdpallcp.zip

cd ${MYHOME}/image

#spark/sqoop/hbase are all with both folder with rev and soft link
#sqoop-1.4.7.bin__hadoop-2.6.0
cp /tmp/zookeeper.tar.gz ./
#   no dep, pure client
cp /tmp/sqoop.tar.gz ./
#   totally depends on ENV
#spark-2.4.4-bin-hadoop2.7
cp /tmp/spark.tar.gz ./
cp /tmp/spark_shared_jars.tar.gz ./
#   spark/conf/
#     core-site.xml
#     hdfs-site.xml
#     -------------
#     hive-site.xml
cp /tmp/hive.tar.gz ./
#  hive/conf/
#    hive-site.xml
#    hadoop depends on ENV
#hbase-2.2.2
#cp /tmp/hbase.tar.gz ./, alreay in image
#   hbase/conf
#     core-site.xml
#     hdfs-site.xml
#     -------------
#     hbase-site.xml
#     hbase-env.sh
#cp /tmp/flink.tar.gz ./
#   no dep, pure client
cp /tmp/kafka.tar.gz ./
#   no dep, pure client

HADOOPREV=3.2.1
HBASEREV=2.2.2

file=Dockerfile.hdpallcp
cat << \EOF > ${file}
FROM master01:30500/chenseanxy/hbase:(HBASEREV)-hadoop(HADOOPREV)

# Add libs
ADD zookeeper.tar.gz /usr/local
ADD sqoop.tar.gz /usr/local
ADD spark.tar.gz /usr/local
ADD spark_shared_jars.tar.gz /usr/local
ADD hive.tar.gz /usr/local
ADD kafka.tar.gz /usr/local

ENV HADOOP_HOME=/usr/local/hadoop \
    YARN_HOME=/usr/local/hadoop \
    ZOOKEEPER_HOME=/usr/local/zookeeper \
    SQOOP_HOME=/usr/local/sqoop \
    SPARK_HOME=/usr/local/spark \
    HIVE_HOME=/usr/local/hive \
    HBASE_HOME=/opt/hbase

ENV MYHOME=/usr/local

ENV PATH=${PATH}:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HADOOP_HOME/lib:$HBASE_HOME/bin:$HIVE_HOME/bin:$SPARK_HOME/bin:$SQOOP_HOME/bin:{ZOOKEEPER_HOME}/bin:{MYHOME}/kafka/bin

WORKDIR ${MYHOME}
EOF
sed -i "s@(HBASEREV)@${HBASEREV}@g" ${file}
sed -i "s@(HADOOPREV)@${HADOOPREV}@g" ${file}

docker build -f Dockerfile.hdpallcp -t master01:30500/bronzels/hdpallcp:0.1 ./
docker push master01:30500/bronzels/hdpallcp:0.1

file=values.yaml
cp ${file} ${file}.bk
sed -i 'pullPolicy: IfNotPresent@pullPolicy: Always@g' ${file}
