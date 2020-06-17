cd ~
MYHOME=~/hdpallcp
#rm -rf ${MYHOME}

unzip hdpallcp.zip

#mkdir -p ${MYHOME}/image
cd ${MYHOME}/image

#spark/sqoop/hbase are all with both folder with rev and soft link
#sqoop-1.4.7.bin__hadoop-2.6.0
cp /tmp/zookeeper.tar.gz ./
#   no dep, pure client
cp /tmp/sqoop.tar.gz ./
#   totally depends on ENV
#spark-2.4.4-bin-hadoop2.7
cp /tmp/spark.tar.gz ./
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

cp ~/source.list.ubuntu.16.04 source.list

HADOOPREV=3.2.1
HBASEREV=2.2.2

file=entrypoint.sh
cat << \EOF > ${file}
. $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

if id -u hive ; then
    echo "hive user exists";
else
    echo "Creating hive user";
    groupadd -g 500 -r hive
    useradd --comment "Hive user" -u 500 --shell /bin/bash -M -r -g hive hive
    groupadd supergroup
    usermod -a -G supergroup hive
    su - hive -s /bin/bash -c "hdfs dfsadmin -refreshUserToGroupsMappings"
fi

service ssh start

exec $@
EOF
chmod a+x ${file}

file=Dockerfile.hdpallcp
cat << \EOF > ${file}
FROM master01:30500/chenseanxy/hbase-ubu16ssh:(HBASEREV)-hadoop(HADOOPREV)

ENV MYHOME=/usr/local
WORKDIR ${MYHOME}

ADD entrypoint.sh bin/

# Add libs
ADD zookeeper.tar.gz ./
ADD sqoop.tar.gz ./
ADD spark.tar.gz ./
ADD hive.tar.gz ./
ADD kafka.tar.gz ./

ENV HADOOP_HOME=${MYHOME}/hadoop \
    YARN_HOME=${MYHOME}/hadoop \
    ZOOKEEPER_HOME=${MYHOME}/zookeeper \
    SQOOP_HOME=${MYHOME}/sqoop \
    SPARK_HOME=${MYHOME}/spark \
    HIVE_HOME=${MYHOME}/hive \
    HBASE_HOME=/opt/hbase

ENV PATH=${PATH}:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HADOOP_HOME/lib:$HBASE_HOME/bin:$HIVE_HOME/bin:$SPARK_HOME/bin:$SQOOP_HOME/bin:{ZOOKEEPER_HOME}/bin:{MYHOME}/bin:{MYHOME}/kafka/bin

ENTRYPOINT ["entrypoint.sh"]
CMD set -e -x && tail -f /dev/null
EOF
sed -i "s@(HBASEREV)@${HBASEREV}@g" ${file}
sed -i "s@(HADOOPREV)@${HADOOPREV}@g" ${file}

docker build -f Dockerfile.hdpallcp -t master01:30500/bronzels/hdpallcp:0.1 ./
docker push master01:30500/bronzels/hdpallcp:0.1

file=values.yaml
cp ${file} ${file}.bk
sed -i 'pullPolicy: IfNotPresent@pullPolicy: Always@g' ${file}
