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
#cp /tmp/scripts.tar.gz ./
#   no dep, pure client

HADOOPREV=3.2.1
HBASEREV=2.2.2

file=Dockerfile
cat << EOF > ${file}
FROM master01:30500/chenseanxy/hbase:(HBASEREV)-hadoop(HADOOPREV)

# Add libs
ADD zookeeper.tar.gz /usr/local
ADD sqoop.tar.gz /usr/local
ADD spark.tar.gz /usr/local
ADD spark_shared_jars.tar.gz /usr/local
ADD hive.tar.gz /usr/local
ADD kylin.tar.gz /usr/local
ADD kafka.tar.gz /usr/local
#ADD scripts.tar.gz /usr/local

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

WORKDIR ${MYHOME}

CMD nohup ${HIVE_HOME}/bin/hive --service hiveserver2 >> ${HIVE_HOME}/logs/hiveserver2.log 2>&1 &
CMD nohup ${KYLIN_HOME}/bin/kylin.sh start

# hive-server2 ports
EXPOSE 9084
# kylin ports
EXPOSE 7070

EOF
sed -i "s@(HBASEREV)@${HBASEREV}@g" ${file}
sed -i "s@(HADOOPREV)@${HADOOPREV}@g" ${file}

file=values.yaml
cat << EOF > ${file}
# The base hadoop image to use for all components.
# See this repo for image build details: https://github.com/Comcast/kube-yarn/tree/master/image


image:
  repository: master01:30500/bronzels/hdpallcl
  tag: 0.1
  pullPolicy: Always

resources: {}

# Also deploy hive-metastore requirement
metastore:
  enabled: true

# Also deploy hdfs requirement
hdfs:
  enabled: true

conf:
  hbaseSite:
  hiveSite:
    # if not set, default hive.metastore.uris is default uri
    # from metastore requirement: "thrift://{{.Release.Name}}-metastore:9083"
    hive.metastore.uris:
  hdfsAdminUser: root
  # if not set, default is configMap from hdfs requirement {{.Release.Name}}-hdfs-hadoop
  hadoopConfigMap:
  # to manually provide hadoop config attributes instead of hadoopConfigMap.
  # hadoopSite:
  #   coreSite:
  #     fs.defaultFS: hdfs://hdfs-cluster:8020
  #   hdfsSite:
  #   ...
EOF
sed -i 'pullPolicy: Always@pullPolicy: IfNotPresent@g' ${file}

file=Chart.yaml
cat << EOF > ${file}
apiVersion: v1
appVersion: 2.3.6
description: The Apache Hive ™ data warehouse software facilitates reading, writing, and managing large datasets
  residing in distributed storage using SQL. Structure can be projected onto data already in storage. A command
  line tool and JDBC driver are provided to connect users to Hive.
home: https://hive.apache.org/
icon: https://hive.apache.org/images/hive_logo_medium.jpg
maintainers:
- email: bronzels@hotmail.com
  name: bronzels
name: hdpallcli
sources:
- https://github.com/apache/hive
- https://github.com/gradiant/charts
- https://github.com/big-data-europe/docker-hive
version: 0.1.0
EOF

FROM master01:30500/chenseanxy/hbase:(HBASEREV)-hadoop(HADOOPREV)
file=README.md
cat << EOF > ${file}
hdpallcli
====
Hadoop and all relevant or irrelevant client is started with SSH enable as stateful set. Hive server2 and Kylin server is started by same bootstrap.sh by different statefulset name.

Current chart version is `0.1.0`

Source code can be found [here](https://github.com/bronzels/cluster-sh-k8s/blob/master/hadoop/hadoop_hdpallcli.sh)

## Chart Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://master01:30500 | hbase:(HBASEREV)-hadoop(HADOOPREV) | ~0.1 |

## Chart Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| conf.hbaseSite | string | configMapName |  |
| conf.hiveSite | string | configMapName |  |
| conf.hadoopConfigMap | string | configMapName |  |
EOF


cat << EOF > requirements.yaml
dependencies:
EOF

