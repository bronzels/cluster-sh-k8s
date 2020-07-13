
cd ~
git clone https://github.com/chenseanxy/helm-hbase-chart.git
rm -rf helm-hbase-chart.bk
cp -r helm-hbase-chart helm-hbase-chart.bk

HADOOPREV=3.2.1
HBASEREV=2.2.2

mkdir ~/helm-hbase-chart-pkgs
cd ~/helm-hbase-chart-pkgs

sparkrev=2.4.6
kylinrev=3.0.2
sqooprev=1.4.7

wget -c http://archive.apache.org/dist/hbase/${HBASEREV}/hbase-${HBASEREV}-bin.tar.gz

wget -c https://us.mirrors.quenda.co/apache/spark/spark-${sparkrev}/spark-${sparkrev}-bin-hadoop2.7.tgz

wget -c https://cdn.mysql.com//archives/mysql-connector-java-5.1/mysql-connector-java-5.1.47.tar.gz
tar xzvf mysql-connector-java-5.1.47.tar.gz
cp mysql-connector-java-5.1.47/mysql-connector-java-5.1.47.jar mysql-connector-java.jar

#kubectl cp -n hadoop myhv-hive-server-0:/opt/hive/lib/postgresql-jdbc.jar ./postgresql-jdbc.jar

wget -c http://ftp.wayne.edu/apache/sqoop/${sqooprev}/sqoop-${sqooprev}.bin__hadoop-2.6.0.tar.gz

wget -c https://archive.apache.org/dist/kylin/apache-kylin-${kylinrev}/apache-kylin-${kylinrev}-bin-hadoop3.tar.gz
rm -rf apache-kylin-${kylinrev}-bin-hadoop3
tar xzvf apache-kylin-${kylinrev}-bin-hadoop3.tar.gz
rm -rf spark-${sparkrev}-bin-hadoop2.7
tar xzvf spark-${sparkrev}-bin-hadoop2.7.tgz
cp spark-${sparkrev}-bin-hadoop2.7/jars/commons-configuration-1.6.jar apache-kylin-${kylinrev}-bin-hadoop3/lib/
file=apache-kylin-${kylinrev}-bin-hadoop3/conf/kylin.properties
cp ${file} ${file}.bk
cat << \EOF >> ${file}
kylin.web.query-timeout=3000000

kylin.source.hive.keep-flat-table=true
kylin.source.hive.quote-enabled=false

kylin.storage.hbase.coprocessor-mem-gb=30
kylin.storage.partition.max-scan-bytes=0
kylin.storage.hbase.coprocessor-timeout-seconds=270

kylin.engine.spark-conf.spark.master=yarn
kylin.engine.spark-conf.spark.submit.deployMode=cluster
kylin.engine.spark-conf.spark.yarn.queue=default
kylin.engine.spark-conf.spark.driver.memory=2G
kylin.engine.spark-conf.spark.executor.memory=5G
kylin.engine.spark-conf.spark.executor.instances=40
kylin.engine.spark-conf.spark.yarn.executor.memoryOverhead=2048
kylin.engine.spark-conf.spark.shuffle.service.enabled=true
kylin.engine.spark-conf.spark.eventLog.enabled=true
kylin.engine.spark-conf.spark.eventLog.dir=hdfs\:///kylin/spark-history
kylin.engine.spark-conf.spark.history.fs.logDirectory=hdfs\:///kylin/spark-history
kylin.engine.spark-conf.spark.hadoop.yarn.timeline-service.enabled=false
kylin.engine.spark-conf-mergedict.spark.executor.memory=2G
kylin.engine.spark-conf-mergedict.spark.memory.fraction=0.2

kylin.job.scheduler.default=2
kylin.job.lock=org.apache.kylin.storage.hbase.util.ZookeeperJobLock
EOF
tar czvf apache-kylin-${kylinrev}-bin-hadoop3.tar.gz apache-kylin-${kylinrev}-bin-hadoop3

cd ~/helm-hbase-chart

cd image

cp ~/helm-hbase-chart-pkgs/*.tar.gz ./
cp ~/helm-hbase-chart-pkgs/*.tgz ./
cp ~/helm-hbase-chart-pkgs/*.jar ./

mkdir scripts
cp ~/scripts/sqoop_import* scripts/
cp ~/scripts/hdfs* scripts/
cp ~/scripts/hive* scripts/
cp ~/scripts/myhbase* scripts/


file=Dockerfile
cp ~/helm-hbase-chart.bk/image/$file $file
sed -i 's@htrace-core-3.1.0-incubating.jar@htrace-core4-4.2.0-incubating.jar@g' $file
sed -i "/ADD hbase-/i\ENV HADOOP_HOME=\/usr\/local\/hadoop" $file
sed -i "/ADD hbase-/i\ENV HBASE_HOME=\/opt\/hbase" $file
#sed -i "/ADD hbase-/a\RUN sed -i 's@# export HBASE_MANAGES_ZK=true@export HBASE_MANAGES_ZK=false@g' \/opt\/hbase-${HBASEREV}\/conf\/hbase-env.sh" $file
#sed -i "/ADD hbase-/a\RUN sed -i 's@# export HBASE_HEAPSIZE=1G@export HBASE_HEAPSIZE=16G@g' \/opt\/hbase-${HBASEREV}\/conf\/hbase-env.sh" $file
#sed -i "/ADD hbase-/a\RUN sed -i 's@# export HBASE_CLASSPATH=@export HBASE_CLASSPATH=\$HADOOP_HOME/etc/hadoop@g' \/opt\/hbase-${HBASEREV}\/conf\/hbase-env.sh" $file
sed -i "/WORKDIR/i\ADD hbase-env.sh \/opt\/hbase\/conf\n" $file
sed -i '/WORKDIR/a\ENV PATH=$PATH:$HBASE_HOME/bin' $file
sed -i "s@FROM chenseanxy\/hadoop:3.2.1-nolib@FROM master01:30500\/chenseanxy\/hadoop:${HADOOPREV}-nolib@g" Dockerfile
cat << \EOF >> ${file}
RUN sed -i 's@CLASSPATH=${CLASSPATH}:$JAVA_HOME\/lib\/tools.jar@CLASSPATH=${CLASSPATH}:$JAVA_HOME\/lib\/tools.jar:$HBASE_HOME\/lib\/*@g' $HBASE_HOME/bin/hbase
EOF

:<<EOF
export HBASE_OPTS="$HBASE_OPTS -XX:SurvivorRatio=2  -XX:+PrintGCDateStamps  -Xloggc:/var/lib/hadoop2/hbase-2.0.1/gc-regionserver.log -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=1 -XX:GCLogFileSize=512M -server -Xmx16g -Xms16g -Xmn2g -Xss256k -XX:PermSize=256m -XX:MaxPermSize=256m -XX:+UseParNewGC -XX:MaxTenuringThreshold=15  -XX:+CMSParallelRemarkEnabled -XX:+UseCMSCompactAtFullCollection -XX:+CMSClassUnloadingEnabled -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=75 -XX:-DisableExplicitGC "
export HBASE_MASTER_OPTS="$HBASE_MASTER_OPTS -XX:PermSize=128m -XX:MaxPermSize=128m"
export HBASE_REGIONSERVER_OPTS="$HBASE_REGIONSERVER_OPTS -XX:PermSize=128m -XX:MaxPermSize=128m"
EOF

cat << \EOF > hbase-env.sh
#!/usr/bin/env bash
#
#/**
# * Licensed to the Apache Software Foundation (ASF) under one
# * or more contributor license agreements.  See the NOTICE file
# * distributed with this work for additional information
# * regarding copyright ownership.  The ASF licenses this file
# * to you under the Apache License, Version 2.0 (the
# * "License"); you may not use this file except in compliance
# * with the License.  You may obtain a copy of the License at
# *
# *     http://www.apache.org/licenses/LICENSE-2.0
# *
# * Unless required by applicable law or agreed to in writing, software
# * distributed under the License is distributed on an "AS IS" BASIS,
# * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# * See the License for the specific language governing permissions and
# * limitations under the License.
# */

# Set environment variables here.

# This script sets variables multiple times over the course of starting an hbase process,
# so try to keep things idempotent unless you want to take an even deeper look
# into the startup scripts (bin/hbase, etc.)

# The java implementation to use.  Java 1.8+ required.
# export JAVA_HOME=/usr/java/jdk1.8.0/

# Extra Java CLASSPATH elements.  Optional.
# export HBASE_CLASSPATH=
export HBASE_CLASSPATH=$HADOOP_HOME/etc/hadoop

# The maximum amount of heap to use. Default is left to JVM default.
# export HBASE_HEAPSIZE=1G
export HBASE_HEAPSIZE=16G

# Uncomment below if you intend to use off heap cache. For example, to allocate 8G of
# offheap, set the value to "8G".
# export HBASE_OFFHEAPSIZE=1G

# Extra Java runtime options.
# Below are what we set by default.  May only work with SUN JVM.
# For more on why as well as other possible settings,
# see http://hbase.apache.org/book.html#performance
export HBASE_OPTS="$HBASE_OPTS -XX:+UseConcMarkSweepGC"

# Uncomment one of the below three options to enable java garbage collection logging for the server-side processes.

# This enables basic gc logging to the .out file.
# export SERVER_GC_OPTS="-verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps"

# This enables basic gc logging to its own file.
# If FILE-PATH is not replaced, the log file(.gc) would still be generated in the HBASE_LOG_DIR .
# export SERVER_GC_OPTS="-verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:<FILE-PATH>"

# This enables basic GC logging to its own file with automatic log rolling. Only applies to jdk 1.6.0_34+ and 1.7.0_2+.
# If FILE-PATH is not replaced, the log file(.gc) would still be generated in the HBASE_LOG_DIR .
# export SERVER_GC_OPTS="-verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:<FILE-PATH> -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=1 -XX:GCLogFileSize=512M"

# Uncomment one of the below three options to enable java garbage collection logging for the client processes.

# This enables basic gc logging to the .out file.
# export CLIENT_GC_OPTS="-verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps"

# This enables basic gc logging to its own file.
# If FILE-PATH is not replaced, the log file(.gc) would still be generated in the HBASE_LOG_DIR .
# export CLIENT_GC_OPTS="-verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:<FILE-PATH>"

# This enables basic GC logging to its own file with automatic log rolling. Only applies to jdk 1.6.0_34+ and 1.7.0_2+.
# If FILE-PATH is not replaced, the log file(.gc) would still be generated in the HBASE_LOG_DIR .
# export CLIENT_GC_OPTS="-verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:<FILE-PATH> -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=1 -XX:GCLogFileSize=512M"

# See the package documentation for org.apache.hadoop.hbase.io.hfile for other configurations
# needed setting up off-heap block caching.

# Uncomment and adjust to enable JMX exporting
# See jmxremote.password and jmxremote.access in $JRE_HOME/lib/management to configure remote password access.
# More details at: http://java.sun.com/javase/6/docs/technotes/guides/management/agent.html
# NOTE: HBase provides an alternative JMX implementation to fix the random ports issue, please see JMX
# section in HBase Reference Guide for instructions.

# export HBASE_JMX_BASE="-Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"
# export HBASE_MASTER_OPTS="$HBASE_MASTER_OPTS $HBASE_JMX_BASE -Dcom.sun.management.jmxremote.port=10101"
# export HBASE_REGIONSERVER_OPTS="$HBASE_REGIONSERVER_OPTS $HBASE_JMX_BASE -Dcom.sun.management.jmxremote.port=10102"
# export HBASE_THRIFT_OPTS="$HBASE_THRIFT_OPTS $HBASE_JMX_BASE -Dcom.sun.management.jmxremote.port=10103"
# export HBASE_ZOOKEEPER_OPTS="$HBASE_ZOOKEEPER_OPTS $HBASE_JMX_BASE -Dcom.sun.management.jmxremote.port=10104"
# export HBASE_REST_OPTS="$HBASE_REST_OPTS $HBASE_JMX_BASE -Dcom.sun.management.jmxremote.port=10105"

# File naming hosts on which HRegionServers will run.  $HBASE_HOME/conf/regionservers by default.
# export HBASE_REGIONSERVERS=${HBASE_HOME}/conf/regionservers

# Uncomment and adjust to keep all the Region Server pages mapped to be memory resident
#HBASE_REGIONSERVER_MLOCK=true
#HBASE_REGIONSERVER_UID="hbase"

# File naming hosts on which backup HMaster will run.  $HBASE_HOME/conf/backup-masters by default.
# export HBASE_BACKUP_MASTERS=${HBASE_HOME}/conf/backup-masters

# Extra ssh options.  Empty by default.
# export HBASE_SSH_OPTS="-o ConnectTimeout=1 -o SendEnv=HBASE_CONF_DIR"

# Where log files are stored.  $HBASE_HOME/logs by default.
# export HBASE_LOG_DIR=${HBASE_HOME}/logs

# Enable remote JDWP debugging of major HBase processes. Meant for Core Developers
# export HBASE_MASTER_OPTS="$HBASE_MASTER_OPTS -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8070"
# export HBASE_REGIONSERVER_OPTS="$HBASE_REGIONSERVER_OPTS -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8071"
# export HBASE_THRIFT_OPTS="$HBASE_THRIFT_OPTS -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8072"
# export HBASE_ZOOKEEPER_OPTS="$HBASE_ZOOKEEPER_OPTS -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8073"
# export HBASE_REST_OPTS="$HBASE_REST_OPTS -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8074"

# A string representing this instance of hbase. $USER by default.
# export HBASE_IDENT_STRING=$USER

# The scheduling priority for daemon processes.  See 'man nice'.
# export HBASE_NICENESS=10

# The directory where pid files are stored. /tmp by default.
# export HBASE_PID_DIR=/var/hadoop/pids

# Seconds to sleep between slave commands.  Unset by default.  This
# can be useful in large clusters, where, e.g., slave rsyncs can
# otherwise arrive faster than the master can service them.
# export HBASE_SLAVE_SLEEP=0.1

# Tell HBase whether it should manage it's own instance of ZooKeeper or not.
# export HBASE_MANAGES_ZK=true
export HBASE_MANAGES_ZK=false

# The default log rolling policy is RFA, where the log file is rolled as per the size defined for the
# RFA appender. Please refer to the log4j.properties file to see more details on this appender.
# In case one needs to do log rolling on a date change, one should set the environment property
# HBASE_ROOT_LOGGER to "<DESIRED_LOG LEVEL>,DRFA".
# For example:
# HBASE_ROOT_LOGGER=INFO,DRFA
# The reason for changing default to RFA is to avoid the boundary case of filling out disk space as
# DRFA doesn't put any cap on the log size. Please refer to HBase-5655 for more context.

# Tell HBase whether it should include Hadoop's lib when start up,
# the default value is false,means that includes Hadoop's lib.
# export HBASE_DISABLE_HADOOP_CLASSPATH_LOOKUP="true"
EOF


docker images|grep "<none>"|awk '{print $3}'|xargs docker rmi -f

docker images|grep "${HBASEREV}-hadoop${HADOOPREV}"
docker images|grep hbase
docker images|grep hbase|awk '{print $3}'|xargs docker rmi -f
docker images|grep hbase
sudo ansible slavek8s -m shell -a"docker images|grep hbase|awk '{print \$3}'|xargs docker rmi -f"
sudo ansible slavek8s -m shell -a"docker images|grep hbase"

file=Makefile
cp ~/helm-hbase-chart.bk/image/$file $file
sed -i "s@HADOOP_30_VERSION = 3.1.2@HADOOP_30_VERSION = ${HADOOPREV}@g" $file
sed -i "s@HBASE_VERSION = 2.1.7@HBASE_VERSION = ${HBASEREV}@g" $file
sed -i "s@DOCKER_REPO = chenseanxy\/hbase@DOCKER_REPO = master01:30500/chenseanxy\/hbase@g" $file

sed -i 's@30500\/chenseanxy\/hadoop@30500\/chenseanxy\/hadoop-ubu16ssh@g' Dockerfile

cp Makefile Makefile-ubu16ssh
sed -i 's@$(DOCKER) build -t hbase@$(DOCKER) build -t hbase-ubu16ssh@g' Makefile-ubu16ssh
make -f Makefile-ubu16ssh

docker tag hbase-ubu16ssh:${HBASEREV}-hadoop${HADOOPREV} master01:30500/chenseanxy/hbase-ubu16ssh:${HBASEREV}-hadoop${HADOOPREV}
docker push master01:30500/chenseanxy/hbase-ubu16ssh:${HBASEREV}-hadoop${HADOOPREV}

docker images|grep "${HBASEREV}-hadoop${HADOOPREV}"



#export hive_dependency=HIVE_CONF_DIR:$HIVE_HOME/lib/*:$HCAT_HOME/share/hcatalog/hive-hcatalog-core-3.1.2.jar
#export HBASE_CLASSPATH_PREFIX=$HBASE_CLASSPATH_PREFIX:$CATALINA_HOME/bin/bootstrap.jar:$CATALINA_HOME/bin/tomcat-juli.jar:$CATALINA_HOME/lib/*:$hive_dependency
cat << \EOF > other-env.sh
export HADOOP_HOME=/usr/local/hadoop
export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop
export HBASE_HOME=/opt/hbase

export SPARK_HOME=/usr/local/spark
export HIVE_HOME=/usr/local/hive

export KYLIN_HOME=/usr/local/kylin
export CLASSPATH=$CLASSPATH:.:$JAVA_HOME/jre/lib/rt.jar:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export CLASSPATH=$CLASSPATH:$HIVE_HOME/lib/*:$HCAT_HOME/share/hcatalog/hive-hcatalog-core-3.1.2.jar
export CATALINA_HOME=$KYLIN_HOME/tomcat
export HIVE_CONF_DIR=${HIVE_HOME}/conf
export HCAT_HOME=$HIVE_HOME/hcatalog
export LC_ALL=en_US.UTF-8

export SQOOP_HOME=/usr/local/sqoop

export PATH=$PATH:$HADOOP_HOME/bin:$HBASE_HOME/bin:$SPARK_HOME/bin:$HIVE_HOME/bin:$KYLIN_HOME/bin:$SQOOP_HOME/bin
EOF

sed -i 's@30500\/chenseanxy\/hadoop-ubu16ssh:'${HADOOPREV}'-nolib@30500\/bronzels\/hive-ubu16ssh:0.1@g' Dockerfile
cat << EOF >> Dockerfile

WORKDIR /usr/local

RUN apt-get update
RUN apt-get install -y net-tools

ADD spark-${sparkrev}-bin-hadoop2.7.tgz /usr/local/
RUN ln -s /usr/local/spark-${sparkrev}-bin-hadoop2.7 /usr/local/spark

ADD apache-kylin-${kylinrev}-bin-hadoop3.tar.gz /usr/local/
RUN ln -s /usr/local/apache-kylin-${kylinrev}-bin-hadoop3 /usr/local/kylin
RUN mkdir /usr/local/kylin/logs
RUN touch /usr/local/kylin/logs/kylin.log

ADD sqoop-${sqooprev}.bin__hadoop-2.6.0.tar.gz /usr/local/
RUN ln -s /usr/local/sqoop-${sqooprev}.bin__hadoop-2.6.0 /usr/local/sqoop

COPY mysql-connector-java.jar /usr/local/sqoop/lib/

COPY scripts /usr/local/scripts

COPY other-env.sh /usr/local/
RUN echo "source /usr/local/other-env.sh" >> /root/.bashrc

#ENTRYPOINT [ "tail", "-f", "/usr/local/kylin/logs/kylin.log" ]
EOF

docker images|grep "<none>"|awk '{print $3}'|xargs docker rmi -f

docker images|grep "${HBASEREV}-hadoop${HADOOPREV}"
docker images|grep hbase-hvspklgw
docker images|grep hbase-hvspklgw|awk '{print $3}'|xargs docker rmi -f
docker images|grep hbase-hvspklgw
sudo ansible slavek8s -m shell -a"docker images|grep hbase-hvspklgw|awk '{print \$3}'|xargs docker rmi -f"
sudo ansible slavek8s -m shell -a"docker images|grep hbase-hvspklgw"

cp Makefile Makefile-hvspklgw-ubu16ssh
sed -i 's@$(DOCKER) build -t hbase@$(DOCKER) build -t hbase-hvspklgw-ubu16ssh@g' Makefile-hvspklgw-ubu16ssh
make -f Makefile-hvspklgw-ubu16ssh

docker tag hbase-hvspklgw-ubu16ssh:${HBASEREV}-hadoop${HADOOPREV} master01:30500/chenseanxy/hbase-hvspklgw-ubu16ssh:${HBASEREV}-hadoop${HADOOPREV}
docker push master01:30500/chenseanxy/hbase-hvspklgw-ubu16ssh:${HBASEREV}-hadoop${HADOOPREV}



docker images|grep "${HBASEREV}-hadoop${HADOOPREV}"

rm -f *.tar.gz
rm -f *.tgz
rm -f *.jar

cd ~/helm-hbase-chart

file=values.yaml
cp ~/helm-hbase-chart.bk/$file $file
sed -i '/hbaseImage: /a\pullPolicy: Always' ${file}
sed -i "s@hbaseImage: chenseanxy\/hbase:1.4.10-hadoop3.1.2@hbaseImage: master01:30500\/chenseanxy\/hbase-ubu16ssh:${HBASEREV}-hadoop${HADOOPREV}@g" ${file}

file=templates/hbase-configmap.yaml
cp ~/helm-hbase-chart.bk/$file $file
sed -i 's@<value>{{ template \"hbase.name\" . }}-hbase-master:16010<\/value>@<value>{{ .Release.Name }}-hbase-master:16010<\/value>@g' ${file}
#sed -i 's@<value>\/hbase<\/value>@<value>\/hbase-unsecure<\/value>@g' ${file}
#sed -i '/    <\/configuration>/i\      <property>\n        <name>hbase.zookeeper.property.clientPort<\/name>\n        <value>2281<\/value>\n      <\/property>' ${file}
#sed -i '/    <\/configuration>/i\      <property>\n        <name>hbase.unsafe.stream.capability.enforce<\/name>\n        <value>false<\/value>\n      <\/property>' ${file}
#sed -i '/    <\/configuration>/i\      <property>\n        <name>hbase.cluster.distributed<\/name>\n        <value>true<\/value>\n      <\/property>' ${file}
sed -i '/    : ${HADOOP_PREFIX:=\/usr\/local\/hadoop}/a\    : ${HADOOP_HOME:=\/usr\/local\/hadoop}' ${file}
sed -i '/    #!\/bin\/bash/a\    service ssh start' ${file}
sed -i 's@    tail -f \/opt\/hbase\/logs\/*@    #tail -f \/opt\/hbase\/logs\/*@g' ${file}
sed -i '/    #tail -f \/opt\/hbase\/logs\/*/i\
    if [[ "${HOSTNAME}" =~ "hbase-master" || "${HOSTNAME}" =~ "hbase-rs" ]]; then \
      tail -f /opt/hbase/logs/* \
    else \
      tail -f \/usr\/local\/kylin\/logs\/kylin.log \
    fi' ${file}

kubectl delete -f myhb-nfs-pv.yaml
cat << \EOF > myhb-nfs-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: myhb-nfs-pv
  labels:
    storage: myhb-nfs-pv
  annotations:
    kubernetes.io.description: pv-storage
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  storageClassName: nfs
  mountOptions:
    - vers=4
    - port=2149
  nfs:
    path: /
    server: 1110.1110.9.83
EOF
kubectl apply -f myhb-nfs-pv.yaml
kubectl get pv|grep myhb-nfs-pv

kubectl delete -f myhb-nfs-pvc.yaml -n hadoop
cat << \EOF > myhb-nfs-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myhb-nfs-pvc
  labels:
    storage: myhb-nfs-pvc
  annotations:
    kubernetes.io/description: "PersistentVolumeClaim for PV"
spec:
  selector:
    matchLabels:
      storage: myhb-nfs-pv
  accessModes:
    - ReadWriteMany
  volumeMode: Filesystem
  storageClassName: nfs
  resources:
    requests:
      storage: 1Gi
EOF
kubectl apply -f myhb-nfs-pvc.yaml -n hadoop
kubectl get pvc -n hadoop

function fix_statefulset_affinity(){
  myhbasefile=$1
  sed -i '/  serviceName:/i\  selector:\n      matchLabels:\n        app: {{ template "hbase.name" . }}' $myhbasefile
  sed -i '/      affinity:/a\        podAffinity:' $myhbasefile
  sed -i 's@      requiredDuringSchedulingIgnoredDuringExecution:@          requiredDuringSchedulingIgnoredDuringExecution:@g' $myhbasefile
  sed -i 's@          - topologyKey: \"kubernetes.io\/hostname\"@              - topologyKey: \"kubernetes.io\/hostname\"@g' $myhbasefile
  sed -i 's@            labelSelector:@                labelSelector:@g' $myhbasefile
  sed -i 's@              matchLabels:@                  matchLabels:@g' $myhbasefile
  sed -i 's@                app:  {{ \.Values\.hbase\.hdfs\.name }}@                    app:  {{ .Release.Namespace }}@g' $myhbasefile
  sed -i 's@                release: {{ \.Values\.hbase\.hdfs\.release | quote }}@                    release: {{ \.Values\.hbase\.hdfs\.release | quote }}@g' $myhbasefile
}

:<<EOF
    spec:
      affinity:
      requiredDuringSchedulingIgnoredDuringExecution:
          - topologyKey: "kubernetes.io/hostname"
            labelSelector:
              matchLabels:
                app:  {{ template "hbase.name" . }}
                release: {{ .Values.hbase.hdfs.release | quote }}
                component: hdfs-nn
    spec:
      affinity:
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
              - topologyKey: "kubernetes.io/hostname"
                labelSelector:
                  matchLabels:
                    app:  {{ .Release.Namespace }}
                    release: {{ .Values.hbase.hdfs.release | quote }}
                    component: hdfs-nn
EOF
file=templates/hbase-master-statefulset.yaml
cp ~/helm-hbase-chart.bk/$file $file
fix_statefulset_affinity "$file"
sed -i 's@                component: hdfs-nn@                    component: hdfs-nn@g' $file
sed -i '/          name: hbase-configmap/a\
      - name: myhdp-hadoop-config \
        configMap: \
          name: myhdp-hadoop' ${file}
sed -i '/          mountPath: \/tmp\/hbase-config/a\
        - name: myhdp-hadoop-config \
          mountPath: \/usr\/local\/hadoop\/etc\/hadoop' ${file}
sed -i 's@apps/v1beta1@apps/v1@g' ${file}

cp templates/hbase-master-statefulset.yaml templates/hbase-hvspklgw-statefulset.yaml
file=templates/hbase-hvspklgw-statefulset.yaml
sed -i 's@  name: {{ template "hbase.fullname" . }}-master@  name: {{ template "hbase.fullname" . }}-hvspklgw@g' ${file}
sed -i 's@component: hbase-master@component: hbase-hvspklgw@g' $file
sed -i 's@  serviceName: {{ template "hbase.fullname" . }}-master@  serviceName: {{ template "hbase.fullname" . }}-hvspklgw@g' $file
sed -i 's@      - name: hbase-master@      - name: hbase-hvspklgw@g' $file
sed -i 's@       image: {{ .Values.hbaseImage }}@       image: master01:30500\/chenseanxy\/hbase-hvspklgw-ubu16ssh:'${HBASEREV}-hadoop${HADOOPREV}'@g' $file
sed -i '/        readinessProbe:/,+11d' ${file}
#sed -i '/        command:/,+2d' ${file}
sed -i '/          name: hbase-configmap/a\
      - name: myhb-nfs-mnt \
        persistentVolumeClaim: \
          claimName: myhb-nfs-pvc' ${file}
sed -i '/          mountPath: \/tmp\/hbase-config/a\
        - name: myhb-nfs-mnt \
          mountPath: \/usr\/local\/com' ${file}
sed -i '/          name: hbase-configmap/a\
      - name: myhv-hive-config \
        configMap: \
          name: hive-custom-config-cm-ext' ${file}
sed -i '/          mountPath: \/tmp\/hbase-config/a\
        - name: myhv-hive-config \
          mountPath: \/usr\/local\/hive\/conf' ${file}
#sed -i s's@@@g' $file
diff templates/hbase-master-statefulset.yaml templates/hbase-hvspklgw-statefulset.yaml

:<<EOF
spec:
  serviceName: {{ template "hbase.name" . }}-rs
  replicas: {{ .Values.hdfs.dataNode.replicas }}
  template:
    metadata:
      labels:
        app: {{ template "hbase.name" . }}
        release: {{ .Release.Name }}
        component: hbase-rs
      annotations:
        scheduler.alpha.kubernetes.io/affinity: >
            {
              "podAntiAffinity": {
                "preferredDuringSchedulingIgnoredDuringExecution": [{
                  "weight":100,
                  "labelSelector": {
                    "matchExpressions": [{
                      "key": "app",
                      "operator": "In",
                      "values": ["codis-server"]
                    }]
                  },
                  "topologyKey": "kubernetes.io/hostname"
                }]
              }
            }
EOF

:<<EOF
    spec:
      affinity:
      requiredDuringSchedulingIgnoredDuringExecution:
          - topologyKey: "kubernetes.io/hostname"
            labelSelector:
              matchLabels:
                app:  {{ template "hbase.name" . }}
                release: {{ .Values.hbase.hdfs.release | quote }}
                component: hdfs-nn
    spec:
      affinity:
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
              - topologyKey: "kubernetes.io/hostname"
                labelSelector:
                  matchLabels:
                    app:  {{ .Release.Namespace }}
                    release: {{ .Values.hbase.hdfs.release | quote }}
                    component: hdfs-dn
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
              - topologyKey: "kubernetes.io/hostname"
                labelSelector:
                  matchLabels:
                    app:  {{ .Release.Namespace }}
                    release: {{ .Release.Name }}
                    component: hbase-rs
EOF
file=templates/hbase-rs-statefulset.yaml
cp ~/helm-hbase-chart.bk/$file $file
fix_statefulset_affinity "$file"
sed -i 's@                component: hdfs-nn@                    component: hdfs-dn@g' $file
#sed -i '/                    component: hdfs-dn/a\        podAntiAffinity:\n          requiredDuringSchedulingIgnoredDuringExecution:\n              - topologyKey:\ "kubernetes.io\/hostname\"\n                labelSelector:\n                  matchLabels:\n                    app:  {{ .Release.Namespace | quote }}\n                    release: {{ .Release.Name | quote }}\n                    component: hbase-rs' $file
sed -i 's@{{ toYaml .Values.hdfs.nameNode.resources | indent 10 }}@{{ toYaml .Values.hdfs.dataNode.resources | indent 10 }}@g' ${file}
sed -i '/        component: hbase-rs/a\      annotations:\n        scheduler.alpha.kubernetes.io\/affinity: >\n            {\n              \"podAntiAffinity": {\n                \"preferredDuringSchedulingIgnoredDuringExecution\": \[{\n                  \"weight\":100,\n                  \"labelSelector\": {\n                    \"matchExpressions\": \[{\n                      \"key\": \"component\",\n                      \"operator\": \"In\",\n                      \"values\": \[\"hbase-rs\"\]\n                    }\]\n                  },\n                  \"topologyKey\": \"kubernetes.io/hostname\"\n                }\]\n              }\n            }' ${file}

cat << \EOF > templates/hbase-master-web-svc.yaml
# A headless service to create DNS records
apiVersion: v1
kind: Service
metadata:
  name: {{ template "hbase.fullname" . }}-master-web
  labels:
    app: {{ template "hbase.name" . }}
    chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
    release: {{ .Release.Name }}
    heritage: {{ .Release.Service }}
    component: hbase-master
spec:
  type: NodePort
  ports:
  - port: 16010
    name: masterinfoweb
    nodePort: 31010
  selector:
    app: {{ template "hbase.name" . }}
    release: {{ .Release.Name }}
    component: hbase-master
EOF

cat << \EOF > templates/hbase-hvspklgw-ssh-svc.yaml
# A headless service to create DNS records
apiVersion: v1
kind: Service
metadata:
  name: {{ template "hbase.fullname" . }}-hvspklgw-ssh
  labels:
    app: {{ template "hbase.name" . }}
    chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
    release: {{ .Release.Name }}
    heritage: {{ .Release.Service }}
    component: hbase-hvspklgw
spec:
  ports:
  - port: 22
    name: masterssh
  selector:
    app: {{ template "hbase.name" . }}
    release: {{ .Release.Name }}
    component: hbase-master
EOF
cat << \EOF > templates/hbase-hvspklgw-kylin-svc.yaml
# A headless service to create DNS records
apiVersion: v1
kind: Service
metadata:
  name: {{ template "hbase.fullname" . }}-hvspklgw-kylin
  labels:
    app: {{ template "hbase.name" . }}
    chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
    release: {{ .Release.Name }}
    heritage: {{ .Release.Service }}
    component: hbase-hvspklgw
spec:
  ports:
  - port: 7070
    name: kylinrest
    nodePort: 32070
  selector:
    app: {{ template "hbase.name" . }}
    release: {{ .Release.Name }}
    component: hbase-hvspklgw
  type: NodePort
EOF

find ~/helm-hbase-chart -name "*.yaml" | xargs grep 'apps/v1beta1'
find ~/helm-hbase-chart -name "*.yaml" | xargs sed -i 's@apps/v1beta1@apps/v1@g'

#  --set hbase.zookeeper.quorum="myzk-zookeeper-0.myzk-zookeeper-headless\,myzk-zookeeper-1.myzk-zookeeper-headless\,myzk-zookeeper-2.myzk-zookeeper-headles" \
helm install myhb -n hadoop -f values.yaml \
  --set hbase.hdfs.name="myhdp-hadoop" \
  --set hbase.hdfs.release="myhdp" \
  --set hdfs.dataNode.replicas=4 \
  --set hdfs.dataNode.pdbMinAvailable=4 \
  --set hbase.zookeeper.quorum="myzk-zookeeper" \
  --set hdfs.dataNode.resources.requests.memory="4096Mi" \
  --set hdfs.dataNode.resources.requests.cpu="2000m" \
  --set hdfs.dataNode.resources.limits.memory="20480Mi" \
  --set hdfs.dataNode.resources.limits.cpu="4000m" \
  ./
:<<EOF
helm uninstall myhb -n hadoop
kubectl exec myzk-zookeeper-0 -n hadoop -- bin/zkCli.sh deleteall /hbase
kubectl exec myzk-zookeeper-0 -n hadoop -- bin/zkCli.sh deleteall /kylin
kubectl exec -n hadoop -it myhdp-hadoop-hdfs-nn-0 -- /usr/local/hadoop/bin/hdfs dfs -rm -r -f /hbase
kubectl exec -n hadoop -it myhdp-hadoop-hdfs-nn-0 -- /usr/local/hadoop/bin/hdfs dfs -rm -r -f /kylin
kubectl exec myzk-zookeeper-0 -n hadoop -- bin/zkCli.sh ls /
kubectl exec -n hadoop -it myhdp-hadoop-hdfs-nn-0 -- /usr/local/hadoop/bin/hdfs dfs -ls /

kubectl describe pod hbase-rs-0 -n hadoop
kubectl logs hbase-rs-0 -n hadoop

kubectl describe pod myhb-hbase-master-0 -n hadoop
kubectl logs myhb-hbase-master-0 -n hadoop
kubectl exec -it myhb-hbase-master-0 -n hadoop -- bash

kubectl describe pod myhb-hbase-hvspklgw-0 -n hadoop
kubectl logs myhb-hbase-hvspklgw-0 -n hadoop
kubectl exec -it myhb-hbase-hvspklgw-0 -n hadoop -- bash

kubectl exec -it myhb-hbase-master-0 -n hadoop -- bash
  bin/hbase shell
    status
    list
    create 't1', {NAME => 'f1', VERSIONS => 1}, {NAME => 'f2', VERSIONS => 1}, {NAME => 'f3', VERSIONS => 1}
    put 't1', 'r4', 'f1:c1', 'v1'
    put 't1', 'r5', 'f2:c2', 'v2'
    put 't1', 'r6', 'f3:c3', 'v3'
    scan 't1'

kubectl get pod -n hadoop
kubectl get pod -n hadoop -o wide
kubectl get pvc -n hadoop -o wide
kubectl get svc -n hadoop -o wide

EOF

:<<EOF
kubectl run test-myubussh-hmaster -ti --image=praqma/network-multitool --rm=true --restart=Never -- bash
  ssh -p 22 root@myhb-hbase-master-ssh.hadoop

kubectl exec -it myhb-hbase-master-0 -n hadoop -- bash
    #bin/hbase-daemons.sh start thrift2
    bin/hbase-daemons.sh start thrift

kubectl -n hadoop run test-python3 -ti --image=python:3.7 --rm=true --restart=Never -- bash
  pip install happybase
  python3

import happybase
conn = happybase.Connection(host='myhb-hbase-master', port=9090)
tables = conn.tables()
print(tables)
for t in tables:
    print(t)

conn.create_table(
    'my_table',
    {
        'cf1': dict(max_versions=10),
        'cf2': dict(max_versions=1, block_cache_enabled=False),
        'cf3': dict()
    }
)
tables = conn.tables()
for t in tables:
    print(t)


http://master01:31010
EOF

:<<EOF
kubectl -n hadoop run test-ubuntu -ti --image=ubuntu:16.04 --rm=true --restart=Never -- bash
EOF
cat << \EOF > /etc/apt/source.list
deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
EOF
:<<EOF
apt-get update
apt-get install -y telnet
telnet myhb-hbase-master 9090
EOF
