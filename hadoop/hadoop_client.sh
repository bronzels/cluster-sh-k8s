cd ~
MYHOME=~/hadoop-client
mkdir -p ${MYHOME}/template
mkdir -p ${MYHOME}/image

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
#apache-kylin-3.0.1-bin-hadoop3
cp /tmp/kylin.tar.gz ./
#   totally depends on ENV
#cp /tmp/flink.tar.gz ./
#   no dep, pure client
cp /tmp/kafka.tar.gz ./
#   no dep, pure client

HADOOPREV=3.2.1
HBASEREV=2.2.2

cat << EOF > hbase-env.sh
FROM master01:30500/chenseanxy/hbase:${HBASEREV}-hadoop${HADOOPREV}

# Add libs
ADD sqoop.tar.gz /usr/local
ADD spark.tar.gz /usr/local
ADD spark_shared_jars.tar.gz /usr/local
ADD hive.tar.gz /usr/local
ADD kylin.tar.gz /usr/local
ADD kafka.tar.gz /usr/local
ADD scripts.tar.gz /usr/local

ENV HADOOP_HOME=/usr/local/hadoop \
    YARN_HOME=/usr/local/hadoop \
    ZOOKEEPER_HOME=/usr/local/zookeeper \
    SQOOP_HOME=/usr/local/sqoop \
    SPARK_HOME=/usr/local/spark \
    HIVE_HOME=/usr/local/hive \
    HBASE_HOME=/opt/hbase \
    KYLIN_HOME=/usr/local/kylin

ENV MYHOME=/usr/local

ENV PATH=\${PATH}:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HADOOP_HOME/lib:$HBASE_HOME/bin:$HIVE_HOME/bin:$SPARK_HOME/bin:$KYLIN_HOME/bin:$SQOOP_HOME/bin:{ZOOKEEPER_HOME}/bin:{MYHOME}/kafka/bin:{MYHOME}/scripts

WORKDIR {MYHOME}

# hive-server2 ports
EXPOSE x
# kylin ports
EXPOSE x
EOF


