#each
#root
fdisk -l|grep "2 TiB"
parted /dev/nvme0n1
:<<EOF
  mklabel gpt
  mkpart p1
    ext4
    1
    2T
  quit
EOF
mkfs.ext4 /dev/nvme0n1p1
mkdir /app
mount /dev/nvme0n1p1 /app
df|grep "/app"

fdisk -l|grep "2 TiB"
parted /dev/nvme1n1
:<<EOF
  mklabel gpt
  mkpart p1
    ext4
    1
    2T
  quit
EOF
mkfs.ext4 /dev/nvme1n1p1
mkdir /app2
mount /dev/nvme1n1p1 /app2
df|grep "/app"
#fstab



#创建hadoop用户，home目录，设置pwd
useradd -d /app/hadoop -m hadoop
usermod --password $(echo hadoop | openssl passwd -1 -stdin) hadoop
chown hadoop:hadoop /app/hadoop

#hadoop加入docker组
sudo gpasswd -a $USER docker
newgrp docker

#pro-hbase01
#root

cat <<EOF > /etc/ansible/hosts
pro-hbase01 ansible_ssh_user=root ansible_ssh_pass=root
pro-hbase02 ansible_ssh_user=root ansible_ssh_pass=root
pro-hbase03 ansible_ssh_user=root ansible_ssh_pass=root
pro-hbase04 ansible_ssh_user=root ansible_ssh_pass=root

[all]
pro-hbase01
pro-hbase02
pro-hbase03
pro-hbase04

[slave]
pro-hbase02
pro-hbase03
pro-hbase04

EOF
cat <<EOF > /etc/ansible/hosts-hadoop
pro-hbase01 ansible_ssh_user=hadoop ansible_ssh_pass=hadoop
pro-hbase02 ansible_ssh_user=hadoop ansible_ssh_pass=hadoop
pro-hbase03 ansible_ssh_user=hadoop ansible_ssh_pass=hadoop
pro-hbase04 ansible_ssh_user=hadoop ansible_ssh_pass=hadoop

[all]
pro-hbase01
pro-hbase02
pro-hbase03
pro-hbase04

[slave]
pro-hbase02
pro-hbase03
pro-hbase04

EOF

1110.1110.1.62 pro-hbase01
1110.1110.11.47 pro-hbase02
1110.1110.13.106 pro-hbase03
1110.1110.3.169 pro-hbase04
cat <<EOF >> /etc/hosts

1110.1110.1.62 hk-prod-bigdata-slave-1-62
1110.1110.11.47 hk-prod-bigdata-slave-11-47
1110.1110.13.106 hk-prod-bigdata-slave-13-106
1110.1110.3.169 hk-prod-bigdata-slave-3-169

EOF

#root
ssh-keygen -t rsa -b 2048 -P '' -f ~/.ssh/id_rsa
cat <<EOF > ssh-addkey.yml
# ssh-addkey.yml
---
- hosts: all
  gather_facts: no

  tasks:

  - name: install ssh key
    authorized_key: user=root
                    key="{{ lookup('file', '/root/.ssh/id_rsa.pub') }}"
                    state=present
EOF
ssh-keyscan pro-hbase01 pro-hbase02 pro-hbase03 pro-hbase04
ansible-playbook ~/ssh-addkey.yml

#hadoop
ssh-keygen -t rsa -b 2048 -P '' -f ~/.ssh/id_rsa
cat <<EOF > ssh-addkey.yml
# ssh-addkey.yml
---
- hosts: all
  gather_facts: no

  tasks:

  - name: install ssh key
    authorized_key: user=root
                    key="{{ lookup('file', '/app/hadoop/.ssh/id_rsa.pub') }}"
                    state=present
EOF
ssh-keyscan pro-hbase01 pro-hbase02 pro-hbase03 pro-hbase04
ansible-playbook ~/ssh-addkey.yml

ansible all -m shell -a"cat /etc/fstab"
ansible slave -m copy -a"src=/etc/hosts dest=/etc"
ansible all -m shell -a"cp /etc/fstab /etc/fstab.bk"
#root
cat << \EOF > /root/add-newdev-fstab.sh
#!/bin/bash

#examples:
#  add-newdev-fstab.sh nvme0n1p1 /app ext4
#  add-newdev-fstab.sh nvme1n1p1 /app2 ext4
#

devname=$1
echo "devname:${devname}"
mntpath=$2
echo "mntpath:${mntpath}"
fs=$3
echo "fs:${fs}"

devid=`blkid /dev/${devname} | sed -e 's/.*UUID="\(.*\)" TYPE=.*/\1/'`
echo "UUID=${devid} ${mntpath}   ${fs} errors=remount-ro 0       0" >> /etc/fstab

EOF
ansible slave -m copy -a"src=/root/add-newdev-fstab.sh dest=/root/"
ansible all -m shell -a"chmod a+x /root/add-newdev-fstab.sh"
ansible all -m shell -a"blkid /dev/nvme0n1p1;/root/add-newdev-fstab.sh nvme0n1p1 /app ext4;cat /etc/fstab"
ansible all -m shell -a"blkid /dev/nvme1n1p1;/root/add-newdev-fstab.sh nvme1n1p1 /app2 ext4;cat /etc/fstab"




#配置操作系统和网络的限制
ansible all -m shell -a"echo 'net.ipv4.tcp_tw_reuse = 1' >> /etc/sysctl.conf"
ansible all -m shell -a"tail -20 /etc/sysctl.conf"
ansible all -m shell -a"sysctl -p"




ansible all -m shell -a"chown -R hadoop:hadoop /app"
ansible all -m shell -a"chown -R hadoop:hadoop /app2"

#给hadoop设置sudo
sed -i '/root    ALL=(ALL:ALL) ALL/a\hadoop  ALL=(ALL) NOPASSWD: ALL' /etc/sudoers
ansible slave -m shell -a"cp /etc/sudoers /etc/sudoers.bk"
ansible slave -m copy -a"src=/etc/sudoers dest=/etc"

#给hadoop设置bash
ansible all -m shell -a"cp /etc/passwd /etc/passwd.bk"
sed -i 's@hadoop:x:1001:1001::\/app\/hadoop:\/bin\/sh@hadoop:x:1001:1001::\/app\/hadoop:\/bin\/bash@g' /etc/passwd
ansible slave -m copy -a"src=/etc/passwd dest=/etc"

ansible all -m shell -a"cp /app/hadoop/.bashrc /app/hadoop/.bashrc.bk"
ansible all -m shell -a"cp /home/ubuntu/.bashrc /app/hadoop/.bashrc"
ansible all -m shell -a"chown hadoop:hadoop /app/hadoop/.bashrc"
ansible all -m shell -a"chown hadoop:hadoop /app/hadoop/.bashrc.bk"

#hadoop
ssh-keygen -t rsa -b 2048 -P '' -f ~/.ssh/id_rsa

#hadoop
cat <<EOF > ssh-addkey.yml
# ssh-addkey.yml
---
- hosts: all
  gather_facts: no

  tasks:

  - name: install ssh key
    authorized_key: user=hadoop
                    key="{{ lookup('file', '/app/hadoop/.ssh/id_rsa.pub') }}"
                    state=present
EOF
ssh-keyscan pro-hbase01 pro-hbase02 pro-hbase03 pro-hbase04
ansible-playbook -i /etc/ansible/hosts-hadoop ~/ssh-addkey.yml

#hadoop
cat << \EOF > ~/other-env.sh
export JAVA_HOME=/app/hadoop/jdk
export AIRFLOW_HOME=/app/hadoop/venvs/airflow

export ZOOKEEPER_HOME=/app/hadoop/zookeeper
export KAFKA_HOME=/app/hadoop/kafka
export HADOOP_HOME=/app/hadoop/hadoop
export HADOOP_MAPRED_HOME=/app/hadoop/hadoop
export HADOOP_HDFS_HOME=/app/hadoop/hadoop
export HADOOP_COMMON_HOME=/app/hadoop/hadoop
export YARN_HOME=/app/hadoop/hadoop
export HADOOP_CONF_DIR=/app/hadoop/hadoop/etc/hadoop

export HBASE_HOME=/app/hadoop/hbase
export HIVE_HOME=/app/hadoop/hive

export SCALA_HOME=/app/hadoop/scala
export SPARK_HOME=/app/hadoop/spark

export CONFLUENT_HOME=/app/hadoop/confluent
export SQOOP_HOME=/app/hadoop/sqoop

export GOPATH=/app/hadoop/gopath
export FLINK_HOME=/app/hadoop/flink
export KYLIN_HOME=/app/hadoop/kylin

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/app/hadoop/scripts:$JAVA_HOME/bin:$ZOOKEEPER_HOME/bin:$KAFKA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HADOOP_HOME/lib:$HBASE_HOME/bin:$HIVE_HOME/bin:$SCALA_HOME/bin:$SPARK_HOME/bin:$SPARK_HOME/sbin:$CONFLUENT_HOME/bin:$SQOOP_HOME/bin:$FLINK_HOME/bin:$KYLIN_HOME/bin:$PATH
EOF

sed  -i '1 i\source /app/hadoop/other-env.sh' ~/.bashrc

ansible slave -i /etc/ansible/hosts-hadoop -m copy -a"src=~/.bashrc dest=~/"
ansible slave -i /etc/ansible/hosts-hadoop -m copy -a"src=~/other-env.sh dest=~/"

ansible all -i /etc/ansible/hosts-hadoop -m copy -a"src=/tmp/jdk-8u251-linux-x64.tar.gz dest=~/"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"tar xzvf ~/jdk-8u251-linux-x64.tar.gz;ln -s jdk1.8.0_251 jdk"

ansible all -i /etc/ansible/hosts-hadoop -m shell -a"java -version"

#在beta 01打包所有的java免安装软件
tar czvf /app2/java-sws-master.tgz fm/sh fm/sql scripts sqoop sqoop-1.4.7.bin__hadoop-2.6.0 hive apache-hive-3.1.2-bin scala scala-2.11.12 spark spark-2.4.4-bin-hadoop2.7 presto-server presto-server-0.218 zookeeper apache-zookeeper-3.5.6-bin kafka kafka_2.11-2.4.0 spark_shared_jars confluent confluent-5.3.2 debezium-connector-mysql debezium-connector-mongodb debezium-connector-postgres hadoop hadoop-3.1.2 --exclude=apache-kylin-3.0.1-bin-hadoop3/logs --exclude=spark-2.4.4-bin-hadoop2.7/logs --exclude=kafka_2.11-2.4.0/logs --exclude=confluent-5.3.2/logs --exclude=hadoop-3.1.2/logs
#scp到aws的master的/app/hadoop目录，解压
#在beta slave打包所有的java免安装软件
tar czvf /app2/java-sws-slave.tgz scripts scala scala-2.11.12 spark spark-2.4.4-bin-hadoop2.7 presto-server presto-server-0.218 zookeeper apache-zookeeper-3.5.6 kafka kafka_2.11-2.4.0 spark_shared_jars confluent confluent-5.3.2 debezium-connector-mysql debezium-connector-mongodb debezium-connector-postgres hadoop hadoop-3.1.2 --exclude=spark-2.4.4-bin-hadoop2.7/logs --exclude=kafka_2.11-2.4.0/logs --exclude=confluent-5.3.2/logs --exclude=hadoop-3.1.2/logs
#scp到aws的slaves的/app/hadoop目录
ansible slave -i /etc/ansible/hosts-hadoop -m shell -a"tar xzvf ~/java-sws-slave.tgz"

#建立exclude掉的logs目录
cd ~;mkdir apache-kylin-3.0.1-bin-hadoop3/logs;mkdir spark-2.4.4-bin-hadoop2.7/logs;mkdir hbase-2.2.2/logs;mkdir kafka_2.11-2.4.0/logs;mkdir confluent-5.3.2/logs;mkdir hadoop-3.1.2/logs
ansible slave -i /etc/ansible/hosts-hadoop -m shell -a"cd ~;mkdir spark-2.4.4-bin-hadoop2.7/logs;mkdir hbase-2.2.2/logs;mkdir kafka_2.11-2.4.0/logs;mkdir confluent-5.3.2/logs;mkdir hadoop-3.1.2/logs"

#建立2块数据硬盘上的数据目录
#zookeeper
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"mkdir -p /app/data/zookeeper/data"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"mkdir -p /app/data/zookeeper/logs"
#hadoop
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"mkdir -p /app/data/hadoop/hdfs/temp"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"mkdir -p /app/data/hadoop/hdfs/name"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"mkdir -p /app/data/hadoop/hdfs/data"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"mkdir -p /app/data/hadoop/hdfs/journaldata"
#spark
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"mkdir -p /app/hadoop/spark/tmp"
#kafka
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"mkdir -p /app/data/kafka/logs"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"mkdir -p /app2/data/kafka/logs"
#pika
ansible -i /etc/ansible/hosts-hadoop slave -m shell -a"rm -rf /app/pika"
ansible -i /etc/ansible/hosts-hadoop slave -m shell -a"mkdir -p /app/pika/stdlog/"
ansible -i /etc/ansible/hosts-hadoop slave -m shell -a"mkdir -p /app/pika/log/"
ansible -i /etc/ansible/hosts-hadoop slave -m shell -a"mkdir -p /app/pika/db/"
ansible -i /etc/ansible/hosts-hadoop slave -m shell -a"mkdir -p /app/pika/dump/"
ansible -i /etc/ansible/hosts-hadoop slave -m shell -a"mkdir -p /app/pika/dbsync/"
ansible -i /etc/ansible/hosts-hadoop slave -m shell -a"rm -rf /app/pika_yat"
ansible -i /etc/ansible/hosts-hadoop slave -m shell -a"mkdir -p /app/pika_yat/stdlog/"
ansible -i /etc/ansible/hosts-hadoop slave -m shell -a"mkdir -p /app/pika_yat/log/"
ansible -i /etc/ansible/hosts-hadoop slave -m shell -a"mkdir -p /app/pika_yat/db/"
ansible -i /etc/ansible/hosts-hadoop slave -m shell -a"mkdir -p /app/pika_yat/dump/"
ansible -i /etc/ansible/hosts-hadoop slave -m shell -a"mkdir -p /app/pika_yat/dbsync/"
#codis
ansible -i /etc/ansible/hosts-hadoop all -m shell -a"mkdir -p /app/data/codis/codis-vip"
ansible -i /etc/ansible/hosts-hadoop all -m shell -a"mkdir -p /app/codis_yat/codis-vip"
#kudu
ansible -i /etc/ansible/hosts-hadoop all -m shell -a"rm -rf /app2/kudu"
ansible -i /etc/ansible/hosts-hadoop all -m shell -a"mkdir -p /app2/kudu/data/fs_data_dirs"
ansible -i /etc/ansible/hosts-hadoop all -m shell -a"mkdir -p /app2/kudu/data/fs_metadata_dir"
ansible -i /etc/ansible/hosts-hadoop all -m shell -a"mkdir -p /app2/kudu/data/fs_wal_dir"
ansible -i /etc/ansible/hosts-hadoop all -m shell -a"mkdir -p /app2/kudu/data/log_dir"
ansible -i /etc/ansible/hosts-hadoop all -m shell -a"mkdir -p /app/hadoop/kudu/logs"
#presto
ansible -i /etc/ansible/hosts-hadoop all -m shell -a"mkdir -p /app/hadoop/presto-server/presto-data"

:<<EOF
1110.1110.1.62 hk-prod-bigdata-slave-1-62
1110.1110.11.47 hk-prod-bigdata-slave-11-47
1110.1110.13.106 hk-prod-bigdata-slave-13-106
1110.1110.3.169 hk-prod-bigdata-slave-3-169
EOF

#全程替换 scripts配置
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd ~/scripts;ls|xargs grep beta-hbase0"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd ~/scripts;ls|xargs sed -i 's@beta-hbase0@pro-hbase0@g'"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd ~/scripts;ls|xargs grep beta-hbase0"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd ~/scripts;ls|xargs grep pro-hbase0"

ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd ~/scripts;ls|xargs grep 1110.111.0.11"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd ~/scripts;ls|xargs sed -i 's@1110.111.0.11@1110.1110.1.62@g'"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd ~/scripts;ls|xargs grep 1110.111.0.11"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd ~/scripts;ls|xargs grep 1110.1110.1.62"


#全程替换 zookeeper配置
# beta-hbase0[1-4]到pro-hbase0[1-4]
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cat ~/zookeeper/conf/zoo.cfg"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cat ~/zookeeper/conf/zoo.cfg"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"sed -i 's@beta-hbase0@pro-hbase0@g' ~/zookeeper/conf/zoo.cfg"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cat ~/zookeeper/conf/zoo.cfg"
for i in $(seq 1 3)
do
  myid=$i
  let nameid=i+1
  name=pro-hbase0${nameid}
  file=/app/data/zookeeper/data/myid
  ssh ${name} 'echo '${myid}' > '${file}''
  ssh ${name} "cat ${file}"
done
ansible slave -i /etc/ansible/hosts-hadoop -m shell -a"cat /app/data/zookeeper/data/myid"



#全程替换 hadoop配置
# beta-hbase0[1-4]到pro-hbase0[1-4]
for i in $(seq 1 4)
do
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd ~/hadoop/etc/hadoop;find . -name '*.xml' -o -name '*.properties' -o -name '*.sh' -o -name 'workers'| xargs grep beta-hbase0$i"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd ~/hadoop/etc/hadoop;find . -name '*.xml' -o -name '*.properties' -o -name '*.sh' -o -name 'workers'| xargs sed -i 's@beta-hbase0'$i'@pro-hbase0'$i'@g'"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd ~/hadoop/etc/hadoop;find . -name '*.xml' -o -name '*.properties' -o -name '*.sh' -o -name 'workers'| xargs grep beta-hbase0$i"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd ~/hadoop/etc/hadoop;find . -name '*.xml' -o -name '*.properties' -o -name '*.sh' -o -name 'workers'| xargs grep pro-hbase0$i"
done
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd ~/hadoop/etc/hadoop;find . -name '*.xml' -o -name '*.properties' -o -name '*.sh' -o -name 'workers'| xargs sed -i 's@betahn@prohn@g'"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"sed -i 's@    <value>16384<\/value>@    <value>32768<\/value>@g' ~/hadoop/etc/hadoop/yarn-site.xml"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"sed -i 's@export JAVA_HOME=\/usr\/lib\/jvm\/java-8-oracle@export JAVA_HOME=\/app\/hadoop\/jdk@g' hadoop/etc/hadoop/hadoop-env.sh"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"grep JAVA_HOME hadoop/etc/hadoop/hadoop-env.sh"
#on aliyun/pro-hbase05
scp /app/home/hadoop/hadoop/etc/hadoop/fair-scheduler.xml hadoop@1110.1110.1.62:/app/hadoop/hadoop/etc/hadoop/fair-scheduler.xml
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"rm -rf /app/data/hadoop/hdfs/journaldata/*"
hdfs --workers --daemon start journalnode
#hdfs --workers --daemon stop journalnode
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"jps"
hdfs zkfc -formatZK
hdfs namenode -format
hdfs --daemon start namenode
#hdfs --daemon stop namenode
mapred --daemon start historyserver
jps

scp -r /app/data/hadoop/hdfs/name/current/ pro-hbase02:/app/data/hadoop/hdfs/name/
ssh pro-hbase02 hdfs --daemon start namenode
#ssh pro-hbase02 hdfs namenode -bootstrapStandby

ansible all -i /etc/ansible/hosts-hadoop -m shell -a"jps"
stop-all.sh
start-all.sh
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"jps"

sudo groupadd supergroup
sudo usermod -a -G supergroup hadoop
hdfs dfsadmin -refreshUserToGroupsMappings

#神策存量数据同步缓存目录
hadoop fs -mkdir /sensorsdata
#如果运行神策local模式，并且不在cp上运行，需要在那台机器上建立神策流处理同步程序存放目录
mkdir -p ~/fm/str

hadoop fs -ls
yarn applciation -list
yarn node -list
hadoop jar ~/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-3.1.2-tests.jar TestDFSIO -write -nrFiles 5 -fileSize 128MB -resFile /tmp/TestDFSIOwrite.txt



#全程替换 spark配置
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"sed -i 's@export JAVA_HOME=\/usr\/lib\/jvm\/java-8-oracle@export JAVA_HOME=\/app\/hadoop\/jdk@g' ~/spark/conf/spark-env.sh"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"grep JAVA_HOME ~/spark/conf/spark-env.sh"
spark-submit --class org.apache.spark.examples.SparkPi \
    --master yarn \
    --deploy-mode client \
    --driver-memory 4g \
    --executor-memory 2g \
    --executor-cores 1 \
    --queue root.default \
    examples/jars/spark-examples*.jar \
    10



#全程替换 hive配置
mkdir -p /app/docker/mysql/hive
sudo rm -rf /app/docker/mysql/hive/*
docker run --name=mysql_hive \
-p 3307:3306 \
-e MYSQL_ROOT_PASSWORD=root \
-v /app/docker/mysql/hive:/var/lib/mysql \
-d mysql:5.7
#！！！手工，登录修改mysql root密码
docker exec -it `docker ps  |grep mysql_hive | awk '{print $1}'` bash
  mysql -P3306 -uroot -proot
      FLUSH PRIVILEGES;
      USE mysql;
      ALTER USER 'root'@'%' IDENTIFIED BY 'root';
      GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION;
      FLUSH PRIVILEGES;
      CREATE DATABASE hive DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
      GRANT ALL ON hive.* TO 'hive'@'%' IDENTIFIED BY 'hive';
      FLUSH PRIVILEGES;
mysql -h pro-hbase01 -P3307 -uroot -proot -e "SHOW DATABASES"
mysql -h pro-hbase01 -P3307 -uhive -phive -D hive -e "SHOW TABLES"
sed -i 's@beta-hbase0@pro-hbase0@g' hive/conf/hive-site.xml
sed -i 's@hive_gun@hive@g' hive/conf/hive-site.xml
hive/bin/schematool -dbType mysql -initSchema
myhive_metastore.sh
netstat -nlap|grep 9083
myhive_server.sh
netstat -nlap|grep 9084
jps|grep RunJar
hadoop fs -mkdir -p /user/hive/warehouse
hadoop fs -chmod g+w /user/hive/warehouse



#全程替换 hbase配置
#从beta-hbase01 打包copy hbase和软连接
tar czvf hbase.tgz hbase hbase-2.2.2 --exclude=hbase-2.2.2/logs
scp hbase.tgz hadoop@1110.1110.1.62:/app/hadoop/
tar xzvf hbase.tgz
sed -i 's@export JAVA_HOME=\/usr\/lib\/jvm\/java-8-oracle@export JAVA_HOME=\/app\/hadoop\/jdk@g' ~/hbase/conf/hbase-env.sh
grep JAVA_HOME ~/hbase/conf/hbase-env.sh
sed -i 's@export HBASE_HEAPSIZE=5G@export HBASE_HEAPSIZE=16G@g' ~/hbase/conf/hbase-env.sh
grep HBASE_HEAPSIZE ~/hbase/conf/hbase-env.sh
sed -i 's@betahn@prohn@g' ~/hbase/conf/hbase-site.xml
grep prohn ~/hbase/conf/hbase-site.xml
for i in $(seq 2 4)
do
  oldname=beta-hbase0${i}
  newname=pro-hbase0${i}
  sed -i "s@${oldname}@${newname}@g" ~/hbase/conf/hbase-site.xml
  sed -i "s@${oldname}@${newname}@g" ~/hbase/conf/regionservers
done
grep pro-hbase0 ~/hbase/conf/hbase-site.xml
cat ~/hbase/conf/regionservers
mkdir hbase/logs
rm -f hbase.tgz
tar czvf hbase.tgz hbase hbase-2.2.2
ansible slave  -i /etc/ansible/hosts-hadoop -m shell -a"cd /app/hadoop;rm -rf hbase hbase-2.2.2;ls -l"
ansible slave  -i /etc/ansible/hosts-hadoop -m copy -a"src=/app/hadoop/hbase.tgz dest=/app/hadoop"
ansible slave  -i /etc/ansible/hosts-hadoop -m shell -a"cd /app/hadoop;tar xzvf hbase.tgz"
ansible all -m shell -a"grep JAVA_HOME /app/hadoop/hbase/conf/hbase-env.sh"
ansible all -m shell -a"grep hbase0 /app/hadoop/hbase/conf/hbase-site.xml"
ansible all -m shell -a"grep prohn /app/hadoop/hbase/conf/hbase-site.xml"
start-hbase.sh
#stop-hbase.sh
hbase-daemon.sh start thrift -p 9050
netstat -nlap|grep 9050
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"jps"



#全程替换 kylin配置
#从beta-hbase01 打包copy kylin和软连接
ansible all -m shell -a"cd /app/hadoop;rm -rf apache-kylin-3.0.1-bin-hadoop3 kylin;ls -l"
tar czvf kylin.tgz apache-kylin-3.0.1-bin-hadoop3 kylin --exclude=apache-kylin-3.0.1-bin-hadoop3/logs
scp kylin.tgz hadoop@1110.1110.1.62:/app/hadoop/
tar xzvf kylin.tgz
cat << \EOF >> kylin/conf/kylin.properties
kylin.web.query-timeout=3000000
kylin.source.hive.keep-flat-table=true
kylin.source.hive.quote-enabled=false

kylin.storage.hbase.coprocessor-mem-gb=30
kylin.storage.partition.max-scan-bytes=0
kylin.storage.hbase.coprocessor-timeout-seconds=270

EOF
sed -i 's@kylin.engine.spark-conf.spark.yarn.executor.memoryOverhead=1024@kylin.engine.spark-conf.spark.yarn.executor.memoryOverhead=2048@g' ~/kylin/conf/kylin.properties
kylin.sh start
~/kylin/bin/sample.sh



#编译部署kudu
wget -c https://github.com/apache/kudu/archive/1.11.1.tar.gz
mv 1.11.1.tar.gz kudu-1.11.1.tar.gz
tar xzvf kudu-1.11.1.tar.gz
cd kudu-1.11.1
sudo apt-get install -y autoconf automake curl flex g++ gcc gdb git \
  krb5-admin-server krb5-kdc krb5-user libkrb5-dev libsasl2-dev libsasl2-modules \
  libsasl2-modules-gssapi-mit libssl-dev libtool lsb-release make ntp \
  openssl patch pkg-config python rsync unzip vim-common
sudo apt-get -y install libmemkind0
sudo apt-get -y install libnuma1 libnuma-dev
git clone https://github.com/memkind/memkind.git
cd memkind
./build.sh --prefix=/usr
sudo apt-get remove memkind
sudo make install
sudo ldconfig
sudo apt-get install -y doxygen gem graphviz ruby-dev xsltproc zlib1g-dev
cd ..
thirdparty/build-if-necessary.sh
mkdir -p build/release
cd build/release
../../thirdparty/installed/common/bin/cmake -DCMAKE_BUILD_TYPE=release ../..
make -j4
cd ~
ln -s kudu-1.11.1 kudu
cd ~/kudu/build/release
make DESTDIR=/app/hadoop/kudu install
chmod a+x
cd ~/kudu
mkdir config
#从beta 01 拷贝配置文件
scp -r  /app/hadoop/kudu/config/master.gflagfile hadoop@1110.1110.1.62:/app/hadoop/kudu/config/master.gflagfile
scp -r  /app/hadoop/kudu/config/tserver.gflagfile hadoop@1110.1110.1.62:/app/hadoop/kudu/config/tserver.gflagfile
cd /app/hadoop/kudu/config;
find * | xargs grep beta-hbase0
find * | xargs sed -i 's@beta-hbase0@pro-hbase0@g'
find * | xargs grep beta-hbase0
find * | xargs grep pro-hbase0
find * | xargs grep 1110.111.0.11
cd ~
tar czvf kudu.tgz kudu/logs kudu/usr kudu/config
ansible slave-i /etc/ansible/hosts-hadoop -m copy -a"src=/app/hadoop/kudu.tgz dest=/app/hadoop"
ansible slave-i /etc/ansible/hosts-hadoop -m shell -a"cd /app/hadoop;tar xzvf kudu.tgz;rm -f kudu.tgz"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"chmod a+x /app/hadoop/kudu/usr/local/sbin/*"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"chmod a+x /app/hadoop/kudu/usr/local/bin/*"
ansible slave -i /etc/ansible/hosts-hadoop -m copy -a"src=/app/hadoop/kudu/config dest=/app/hadoop/kudu"
mykuduserver.sh start
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"ps -ef|grep kudu"
ansible slave -i /etc/ansible/hosts-hadoop -m copy -a"src=/app/hadoop/kudu/usr dest=/app/hadoop/kudu"
kudu/usr/local/bin/kudu master list pro-hbase01:7052
kudu/usr/local/bin/kudu tserver list pro-hbase01:7052
kudu/usr/local/bin/kudu table list pro-hbase01:7052


#全程替换 kafka配置
ansible all -m shell -a"cd /app/hadoop/confluent/config;find * | xargs grep beta-hbase0"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd /app/hadoop/confluent/config;find * | xargs sed -i 's@beta-hbase0@pro-hbase0@g'"
ansible all -m shell -a"cd /app/hadoop/confluent/config;find * | xargs grep beta-hbase0"
ansible all -m shell -a"cd /app/hadoop/confluent/config;find * | xargs grep pro-hbase0"

ansible all -m shell -a"cd /app/hadoop/confluent/config;find * | xargs grep 1110.111.0.11"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd /app/hadoop/confluent/config;find * | xargs sed -i 's@1110.111.0.11@1110.1110.1.62@g'"
ansible all -m shell -a"cd /app/hadoop/confluent/config;find * | xargs grep 1110.111.0.11"
ansible all -m shell -a"cd /app/hadoop/confluent/config;find * | xargs grep 1110.1110.1.62"


ansible all -m shell -a"cd /app/hadoop/confluent/config;find * | xargs grep 1110.111.0.12"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd /app/hadoop/confluent/config;find * | xargs sed -i 's@1110.111.0.12@1110.1110.11.47@g'"
ansible all -m shell -a"cd /app/hadoop/confluent/config;find * | xargs grep 1110.111.0.12"
ansible all -m shell -a"cd /app/hadoop/confluent/config;find * | xargs grep 1110.1110.11.47"

ansible all -m shell -a"cd /app/hadoop/confluent/config;find * | xargs grep 1110.111.0.13"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd /app/hadoop/confluent/config;find * | xargs sed -i 's@1110.111.0.13@1110.1110.13.106@g'"
ansible all -m shell -a"cd /app/hadoop/confluent/config;find * | xargs grep 1110.111.0.13"
ansible all -m shell -a"cd /app/hadoop/confluent/config;find * | xargs grep 1110.1110.13.106"

ansible all -m shell -a"cd /app/hadoop/confluent/config;find * | xargs grep 1110.111.0.14"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd /app/hadoop/confluent/config;find * | xargs sed -i 's@1110.111.0.14@1110.1110.3.169@g'"
ansible all -m shell -a"cd /app/hadoop/confluent/config;find * | xargs grep 1110.111.0.14"
ansible all -m shell -a"cd /app/hadoop/confluent/config;find * | xargs grep 1110.1110.3.169"

ansible all -m shell -a"cd /app/hadoop/confluent/config;find * | xargs grep beta_test"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd /app/hadoop/confluent/config;find * | xargs sed -i 's@beta_test@pro_test@g'"
ansible all -m shell -a"cd /app/hadoop/confluent/config;find * | xargs grep beta_test"
ansible all -m shell -a"cd /app/hadoop/confluent/config;find * | xargs grep pro_test"

mykafka1_server.sh start
mykafka1_server.sh status
mykafka1_produce.sh test
mykafka1_consume.sh test from-beginning

mykafka2_server.sh start
mykafka2_server.sh status
mykafka2_produce.sh test
mykafka2_consume.sh test from-beginning



#全程替换 presto配置
ansible all -m shell -a"cd /app/hadoop/confluent/config;find * | xargs grep beta-hbase0"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd /app/hadoop/confluent/config;find * -type f | xargs sed -i 's@beta-hbase0@pro-hbase0@g'"
ansible all -m shell -a"cd /app/hadoop/confluent/config;find * | xargs grep beta-hbase0"
ansible all -m shell -a"cd /app/hadoop/confluent/config;find * | xargs grep pro-hbase0"

ansible all -m shell -a"cd /app/hadoop/confluent/config;find * | xargs grep pro-hbase05"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd /app/hadoop/confluent/config;find * -type f | xargs sed -i 's@pro-hbase05@pro-hbase01@g'"
ansible all -m shell -a"cd /app/hadoop/confluent/config;find * | xargs grep pro-hbase05"
ansible all -m shell -a"cd /app/hadoop/confluent/config;find * | xargs grep pro-hbase06"


ansible all -m shell -a"cd /app/hadoop/confluent/config;find * | xargs grep 1110.111.0.11"
myprestoserver.sh start




#编译部署pika
rm -rf pika
git clone https://github.com/Qihoo360/pika.git
cd pika
git checkout pika_codis

sudo ansible all -m shell -a"apt-get install -y libzip-dev libsnappy-dev libprotobuf-dev protobuf-compiler bzip2"
sudo ansible all -m shell -a"apt-get install -y libgoogle-glog-dev"

#如果机器gcc版本低于gcc4.8，需要切换到gcc4.8或者以上
gcc -v
g++ -v

pikahome=$PWD

make

#从beta-hbase01 copy pika配置文件
scp pika/conf/pika.conf hadoop@1110.1110.1.62:/app/hadoop/pika/conf
scp pika/conf/pika_yat.conf hadoop@1110.1110.1.62:/app/hadoop/pika/conf

find * | xargs grep beta-hbase0
find * | xargs grep 1110.111.0.11
find * | xargs grep 1110.111.0.12

cd ~
tar czvf pika.tgz pika
ansible slave -i /etc/ansible/hosts-hadoop -m copy -a"src=/app/hadoop/pika.tgz dest=/app/hadoop"
ansible slave -i /etc/ansible/hosts-hadoop -m shell -a"cd /app/hadoop;tar xzvf pika.tgz;rm -f pika.tgz"

mypikacluster.sh start
mypikacluster_yat.sh start



#编译部署codis
#root
rev=1.12.9
wget -c https://dl.google.com/go/go${rev}.linux-amd64.tar.gz
tar -C /usr/local -xzf ~/go${rev}.linux-amd64.tar.gz
#hadoop
echo "export PATH=${PATH}:/usr/local/go/bin" >> ~/other-env.sh
source ~/.bashrc
mkdir ~/gopath
echo "export GOPATH=${HOME}/gopath" >> ~/other-env.sh
source ~/.bashrc

mkdir -p $GOPATH/src/github.com/CodisLabs
cd $_ && git clone https://github.com/CodisLabs/codis.git -b release3.2
cd codis
make

#从beta-hbase01 copy codis配置文件
scp -r /app/hadoop/gopath/src/github.com/CodisLabs/codis/ansible hadoop@1110.1110.1.62:/app/hadoop/gopath/src/github.com/CodisLabs/codis/
scp -r /app/hadoop/gopath/src/github.com/CodisLabs/codis/ansible_yat hadoop@1110.1110.1.62:/app/hadoop/gopath/src/github.com/CodisLabs/codis/
find . -name "hosts*" | xargs grep 'ansible_ssh_user=hadoop'
find . -name "hosts*" | xargs sed -i 's@ansible_ssh_user=hadoop ansible_ssh_private_key_file=/app/hadoop/fm_beta_bigdata.pem@ansible_ssh_user=hadoop ansible_ssh_pass=hadoop@g'
find . -name "hosts*" | xargs grep 'ansible_ssh_user=hadoop'
ansible_ssh_user=hadoop ansible_ssh_private_key_file=/app/hadoop/fm_beta_bigdata.pem
find * -type f | xargs grep "beta-hbase0"
find . -type f | xargs sed -i 's@beta-hbase0@pro-hbase0@g'
find * -type f | xargs grep "beta-hbase0"
find * -type f | xargs grep "pro-hbase0"

cd bin

ansible-playbook -i ~/gopath/src/github.com/CodisLabs/codis/ansible/hosts-hadoop ~/gopath/src/github.com/CodisLabs/codis/ansible/site.yml
codis-admin --dashboard=pro-hbase01:18080 --create-group --gid=1         #新建group 1  相当于fe页面“NEW GROUP”按钮
codis-admin --dashboard=pro-hbase01:18080 --group-add     --gid=1   --addr=pro-hbase02:9221   #把server ip:port 加入集群，
codis-admin --dashboard=pro-hbase01:18080 --create-group --gid=2         #新建group 2  相当于fe页面“NEW GROUP”按钮
codis-admin --dashboard=pro-hbase01:18080 --group-add     --gid=2   --addr=pro-hbase03:9221   #把server ip:port 加入集群，
codis-admin --dashboard=pro-hbase01:18080 --create-group --gid=3         #新建group 3  相当于fe页面“NEW GROUP”按钮
codis-admin --dashboard=pro-hbase01:18080 --group-add     --gid=3   --addr=pro-hbase04:9221   #把server ip:port 加入集群，
codis-admin  --dashboard=pro-hbase01:18080 --sync-action --create --addr=pro-hbase02:9221  #相当于fe页面的”SYNC"按钮
codis-admin  --dashboard=pro-hbase01:18080 --sync-action --create --addr=pro-hbase03:9221  #相当于fe页面的”SYNC"按钮
codis-admin  --dashboard=pro-hbase01:18080 --sync-action --create --addr=pro-hbase04:9221  #相当于fe页面的”SYNC"按钮
codis-admin  --dashboard=pro-hbase01:18080 --rebalance --confirm  #相当于fe页面“Rebalance All Slots”按钮

ansible-playbook -i ~/gopath/src/github.com/CodisLabs/codis/ansible_yat/hosts-hadoop ~/gopath/src/github.com/CodisLabs/codis/ansible_yat/site.yml
codis-admin --dashboard=pro-hbase01:18180 --create-group --gid=1         #新建group 1  相当于fe页面“NEW GROUP”按钮
codis-admin --dashboard=pro-hbase01:18180 --group-add     --gid=1   --addr=pro-hbase02:9321   #把server ip:port 加入集群，
codis-admin --dashboard=pro-hbase01:18180 --create-group --gid=2         #新建group 2  相当于fe页面“NEW GROUP”按钮
codis-admin --dashboard=pro-hbase01:18180 --group-add     --gid=2   --addr=pro-hbase03:9321   #把server ip:port 加入集群，
codis-admin --dashboard=pro-hbase01:18180 --create-group --gid=3         #新建group 3  相当于fe页面“NEW GROUP”按钮
codis-admin --dashboard=pro-hbase01:18180 --group-add     --gid=3   --addr=pro-hbase04:9321   #把server ip:port 加入集群，
codis-admin  --dashboard=pro-hbase01:18180 --sync-action --create --addr=pro-hbase02:9321  #相当于fe页面的”SYNC"按钮
codis-admin  --dashboard=pro-hbase01:18180 --sync-action --create --addr=pro-hbase03:9321  #相当于fe页面的”SYNC"按钮
codis-admin  --dashboard=pro-hbase01:18180 --sync-action --create --addr=pro-hbase04:9321  #相当于fe页面的”SYNC"按钮
codis-admin  --dashboard=pro-hbase01:18180 --rebalance --confirm  #相当于fe页面“Rebalance All Slots”按钮



#全程替换 opentsdb配置
tar czvf opentsdb.tgz opentsdb --exclude=opentsdb/log
scp opentsdb.tgz hadoop@1110.1110.1.62:/app/hadoop/
tar xzvf opentsdb.tgz

grep "2181" ~/opentsdb/src/opentsdb_tmp.conf
sed -i 's@tsd.storage.hbase.zk_quorum = beta-hbase02:2281,beta-hbase03:2281,beta-hbase04:2281@tsd.storage.hbase.zk_quorum = 1110.1110.20.191:2181@g' ~/opentsdb/src/opentsdb_tmp.conf
grep "2181" ~/opentsdb/src/opentsdb_tmp.conf
grep "/hbase" ~/opentsdb/src/opentsdb_tmp.conf
sed -i 's@tsd.storage.hbase.zk_basedir = /hbase1@tsd.storage.hbase.zk_basedir = /hbase@g' ~/opentsdb/src/opentsdb_tmp.conf
grep "/hbase" ~/opentsdb/src/opentsdb_tmp.conf
mkdir opentsdb/log
tar czvf opentsdb.tgz opentsdb
ansible slave -m copy -a"src=/app/hadoop/opentsdb.tgz dest=/app/hadoop"
ansible slave -m shell -a"cd /app/hadoop;tar xzvf opentsdb.tgz;rm -f opentsdb.tgz"
curl -ki -X POST -d '{"metric":"testdata", "timestamp":1524900185000, "value":9999.99, "tags":{"key":"value"}}' http://1110.1110.11.47:4344/api/put?sync
curl  -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://1110.1110.11.47:4344/api/query  -d '
    {
        "start": "1970/03/01 00:00:00",
        "end": "2029/12/16 00:00:00",
        "queries": [
            {
                "metric": "testdata",

                "aggregator": "none",
                "tags": {
                    "key": "value"
                }
            }
        ]
    }'




#全程替换 confluent配置
ansible all -m shell -a"cd /app/hadoop/confluent/config;find * -type f | xargs grep beta-hbase0"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd /app/hadoop/confluent/config;find * -type f | xargs sed -i 's@beta-hbase0@pro-hbase0@g'"
ansible all -m shell -a"cd /app/hadoop/confluent/config;find * -type f | xargs grep beta-hbase0"
ansible all -m shell -a"cd /app/hadoop/confluent/config;find * -type f | xargs grep pro-hbase0"

ansible all -m shell -a"cd /app/hadoop/confluent/etc/schema-registry;find * -type f | xargs grep beta-hbase0"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd /app/hadoop/confluent/etc/schema-registry;find * -type f | xargs sed -i 's@beta-hbase0@pro-hbase0@g'"
ansible all -m shell -a"cd /app/hadoop/confluent/etc/schema-registry;find * -type f | xargs grep beta-hbase0"
ansible all -m shell -a"cd /app/hadoop/confluent/etc/schema-registry;find * -type f | xargs grep pro-hbase0"

#启动schema-registry
netstat -nlap|grep 8981
#去各台机器启动confluent实例




#重新部署flink，复制配置
wget -c https://downloads.apache.org/flink/flink-1.11.0/flink-1.11.0-bin-scala_2.11.tgz
tar xzvf flink-1.11.0-bin-scala_2.11.tgz
ln -s flink-1.11.0 flink
scp flink/conf/flink-conf.yaml hadoop@1110.1110.1.62:/app/hadoop/
diff flink-conf.yaml flink/conf/flink-conf.yaml
rm -f flink-conf.yaml
sed -i 's@jobmanager.rpc.address: localhost@jobmanager.rpc.address: pro-hbase01@g' flink/conf/flink-conf.yaml
sed -i 's@jobmanager.memory.process.size: 1600m@jobmanager.memory.process.size: 24576m@g' flink/conf/flink-conf.yaml
sed -i 's@taskmanager.memory.process.size: 1728m@taskmanager.memory.process.size: 40960m@g' flink/conf/flink-conf.yaml
sed -i 's@taskmanager.numberOfTaskSlots: 1@taskmanager.numberOfTaskSlots: 8@g' flink/conf/flink-conf.yaml
sed -i 's@#rest.port: 8081@rest.port: 8089@g' flink/conf/flink-conf.yaml
cat << \EOF > /app/hadoop/flink/conf/workers
pro-hbase02
pro-hbase03
pro-hbase04
EOF
cd
tar czvf flink.tgz flink flink-1.11.0
ansible slave -m shell -a"cd /app/hadoop;rm -rf flink flink-1.11.0"
ansible slave -m copy -a"src=/app/hadoop/flink.tgz dest=/app/hadoop"
ansible slave -m shell -a"cd /app/hadoop;tar xzvf flink.tgz;rm -f flink.tgz"
#复制和部署流处理copy dependency里删掉flink系统jar的部分
ansible slave -m copy -a"src=/tmp/lib.zip dest=/tmp"
ansible all -m shell -a"cd /app/hadoop/flink/lib;unzip -o /tmp/lib.zip"
~/flink/bin/start-cluster.sh
#~/flink/bin/stop-cluster.sh
#ansible all -m copy -a"src=/app/hadoop/tmp/flink-1.11.0/lib dest=/app/hadoop/flink"
#ansible all -m shell -a"rm -rf /app/hadoop/flink/lib"
cat << \EOF >> /app/hadoop/flink/conf/flink-conf.yaml
metrics.reporters: prom
metrics.reporter.prom.class: org.apache.flink.metrics.prometheus.PrometheusReporter
metrics.reporter.prom.port: 19999
EOF
:<<EOF
metrics.reporter.promgateway.class: org.apache.flink.metrics.prometheus.PrometheusPushGatewayReporter
metrics.reporter.promgateway.host: 1110.1110.1.62
metrics.reporter.promgateway.port: 9091
metrics.reporter.promgateway.jobName: myJob
metrics.reporter.promgateway.randomJobNameSuffix: true
metrics.reporter.promgateway.deleteOnShutdown: false
EOF

cd



#部署mongo slave
#参考项目定制工程的《doc/数据库slave实例/建立mongodb slave.md》




#部署airflow
sudo apt-get install -y libsqlite3-dev
#从beta01 copy airflow的整个虚拟环境，解压
tar czvf airflow.tgz airflow --exclude=airflow/logs --exclude=airflow/webserver.out
scp airflow.tgz hadoop@1110.1110.1.62:/app/hadoop/venvs/
cd venvs
tar xzvf airflow.tgz
scp venvs/airflow/airflow.cfg hadoop@1110.1110.1.62:/app/hadoop/venvs/airflow/
scp venvs/airflow/myscheduler.sh hadoop@1110.1110.1.62:/app/hadoop/venvs/airflow/
scp venvs/airflow/mywebserver.sh hadoop@1110.1110.1.62:/app/hadoop/venvs/airflow/
cd /app/hadoop/venvs/airflow
find *  -maxdepth 1 -type f | xargs grep beta-hbase0
find *  -maxdepth 1 -type f | xargs sed -i 's@beta-hbase0@pro-hbase0@g'
find *  -maxdepth 1 -type f | xargs grep beta-hbase0
find *  -maxdepth 1 -type f | xargs grep pro-hbase0
sed -i 's@pro-hbase01:3307@pro-hbase01:3308@g' airflow.cfg
sed -i 's@airflow_beta@airflow@g' airflow.cfg
mkdir -p /app/docker/mysql/airflow/data
mkdir -p /app/docker/mysql/airflow/config
cat << \EOF > /app/docker/mysql/airflow/config/my.cnf
[mysql]
[mysqld]
explicit_defaults_for_timestamp = 1
EOF
sudo rm -rf /app/docker/mysql/airflow/data/*
sudo rm -rf /app/docker/mysql/airflow/config/*
docker run --name=mysql_airflow \
-p 3308:3306 \
-e MYSQL_ROOT_PASSWORD=root \
-v /app/docker/mysql/airflow/config:/etc/mysql \
-v /app/docker/mysql/airflow/data:/var/lib/mysql \
-d mysql:5.7
#！！！手工，登录修改mysql root密码
docker exec -it `docker ps  |grep mysql_airflow | awk '{print $1}'` bash
  mysql -P3306 -uroot -proot
      FLUSH PRIVILEGES;
      USE mysql;
      ALTER USER 'root'@'%' IDENTIFIED BY 'root';
      GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION;
      FLUSH PRIVILEGES;
      CREATE DATABASE airflow DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
      GRANT ALL ON airflow.* TO 'airflow'@'%' IDENTIFIED BY 'airflow';
      FLUSH PRIVILEGES;
mysql -h pro-hbase01 -P3308 -uroot -proot -e "SHOW DATABASES"
mysql -h pro-hbase01 -P3308 -uairflow -pairflow -D airflow -e "SHOW TABLES"




#部署redis
docker run --name myredis -p 6379:6379 -d redis:latest redis-server
sudo apt-get install -y redis-tools
myredis_get_fel.sh
myredis_set_fe.sh
myredis_get_fel.sh




#部署postgresql
#root
echo "deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main" >> /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get update
apt-get install postgresql-client-11 -y
#hadoop
mkdir -p /app2/docker/postgre/mypostgres
sudo rm -rf /app2/docker/postgre/mypostgres/*
docker run --name mypostgres -p 5432:5432 -v /app2/docker/postgre/mypostgres:/var/lib/postgresql/data -e POSTGRES_PASSWORD=postgres -d debezium/postgres
mypostgres.sh




#部署exporter/prometheus/grafana
docker run -itd -p 9308:9308 --name kafka1-exporter danielqsj/kafka-exporter --kafka.server=1110.1110.11.47:9392 --kafka.server=1110.1110.13.106:9392 --kafka.server=1110.1110.3.169:9392
docker run -itd -p 9309:9308 --name kafka2-exporter danielqsj/kafka-exporter --kafka.server=1110.1110.11.47:9492 --kafka.server=1110.1110.13.106:9492 --kafka.server=1110.1110.3.169:9492

docker pull prom/mysqld-exporter
:<<EOF
aws_copytrading_slave  1110.1110.5.250:3306
aws_push_slave  1110.1110.5.250:3307
aws_wallet_slave  1110.1110.5.250:3308
aws_sam_slave  1110.1110.5.250:3309
EOF
docker run -d --restart=always \
  --name mysqld-exporter-copytrading_slave \
  -p 9104:9104 \
  -e DATA_SOURCE_NAME="liuxiangbin:m1njooUE04vc@(1110.1110.5.250:3306)/" \
  prom/mysqld-exporter
docker run -d --restart=always \
  --name mysqld-exporter-aws_push_slave \
  -p 9105:9104 \
  -e DATA_SOURCE_NAME="liuxiangbin:m1njooUE04vc@(1110.1110.5.250:3307)/" \
  prom/mysqld-exporter
docker run -d --restart=always \
  --name mysqld-exporter-aws_wallet_slave \
  -p 9106:9104 \
  -e DATA_SOURCE_NAME="liuxiangbin:m1njooUE04vc@(1110.1110.5.250:3308)/" \
  prom/mysqld-exporter
docker run -d --restart=always \
  --name mysqld-exporter-aws_sam_slave \
  -p 9107:9104 \
  -e DATA_SOURCE_NAME="liuxiangbin:m1njooUE04vc@(1110.1110.5.250:3309)/" \
  prom/mysqld-exporter

mkdir jmx
cd jmx
wget https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.12.0/jmx_prometheus_javaagent-0.12.0.jar
mv jmx_prometheus_javaagent-0.12.0.jar jmx-exporter.jar
file=~/jmx/config.yml
cat << \EOF > ${file}
startDelaySeconds: 0
ssl: false
lowercaseOutputName: false
lowercaseOutputLabelNames: false
rules:
pattern : "kafka.connect<type=connect-worker-metrics>([^:]+):"
name: "kafka_connect_connect_worker_metrics_$1"
pattern : "kafka.connect<type=connect-metrics, client-id=([^:]+)><>([^:]+)"
name: "kafka_connect_connect_metrics_$2"
labels:
client: "$1"
pattern: "debezium.([^:]+)<type=connector-metrics, context=([^,]+), server=([^,]+), key=([^>]+)><>RowsScanned"
name: "debezium_metrics_RowsScanned"
labels:
plugin: "$1"
name: "$3"
context: "$2"
table: "$4"
pattern: "debezium.([^:]+)<type=connector-metrics, context=([^,]+), server=([^>]+)>([^:]+)"
name: "debezium_metrics_$4"
labels:
plugin: "$1"
name: "$3"
context: "$2"
EOF
cd ~
file=~/confluent/bin/connect-distributed
cp ${file} ${file}-debsrc-str-mysql
sed -i 's@exec $(dirname $0)/kafka-run-class $EXTRA_ARGS org.apache.kafka.connect.cli.ConnectDistributed@exec $(dirname $0)/kafka-run-class $EXTRA_ARGS -javaagent:/app/hadoop/jmx/jmx-exporter.jar=7071:/app/hadoop/jmx/config.yml org.apache.kafka.connect.cli.ConnectDistributed@g' ${file}-debsrc-str-mysql
cp ${file} ${file}-debsrc-str-postgre
sed -i 's@exec $(dirname $0)/kafka-run-class $EXTRA_ARGS org.apache.kafka.connect.cli.ConnectDistributed@exec $(dirname $0)/kafka-run-class $EXTRA_ARGS -javaagent:/app/hadoop/jmx/jmx-exporter.jar=7072:/app/hadoop/jmx/config.yml org.apache.kafka.connect.cli.ConnectDistributed@g' ${file}-debsrc-str-postgre
cp ${file} ${file}-debsrc-dw-mysql
sed -i 's@exec $(dirname $0)/kafka-run-class $EXTRA_ARGS org.apache.kafka.connect.cli.ConnectDistributed@exec $(dirname $0)/kafka-run-class $EXTRA_ARGS -javaagent:/app/hadoop/jmx/jmx-exporter.jar=7073:/app/hadoop/jmx/config.yml org.apache.kafka.connect.cli.ConnectDistributed@g' ${file}-debsrc-dw-mysql
cp ${file} ${file}-debsrc-dw-mg-src-src
sed -i 's@exec $(dirname $0)/kafka-run-class $EXTRA_ARGS org.apache.kafka.connect.cli.ConnectDistributed@exec $(dirname $0)/kafka-run-class $EXTRA_ARGS -javaagent:/app/hadoop/jmx/jmx-exporter.jar=7074:/app/hadoop/jmx/config.yml org.apache.kafka.connect.cli.ConnectDistributed@g' ${file}-debsrc-dw-mg-src-src
scp ${file}-debsrc-dw-mg-src-src pro-hbase03:~/confluent/bin/
cp ${file} ${file}-debsrc-dw-mg-dst-src
sed -i 's@exec $(dirname $0)/kafka-run-class $EXTRA_ARGS org.apache.kafka.connect.cli.ConnectDistributed@exec $(dirname $0)/kafka-run-class $EXTRA_ARGS -javaagent:/app/hadoop/jmx/jmx-exporter.jar=7075:/app/hadoop/jmx/config.yml org.apache.kafka.connect.cli.ConnectDistributed@g' ${file}-debsrc-dw-mg-dst-src
scp ${file}-debsrc-dw-mg-dst-src pro-hbase04:~/confluent/bin/
#重新启动所有debezium source connector

go get github.com/wakeful/kafka_connect_exporter
~/gopath/src/github.com/wakeful/kafka_connect_exporter
./build.sh
cd ~
ansible all -m copy -a"src=~/gopath/src/github.com/wakeful/kafka_connect_exporter/release/kafka_connect_exporter-linux-amd64 dest=~/scripts"
ansible all -m shell -a"chmod a+x ~/scripts/kafka_connect_exporter-linux-amd64"
#有多少个confluent sink进程，启动多少个
nohup kafka_connect_exporter-linux-amd64 -listen-address :9001 -scrape-uri http://pro-hbase01:8083 1>kafka_connect_exporter.log.9001 2>&1 &
nohup kafka_connect_exporter-linux-amd64 -listen-address :9002 -scrape-uri http://pro-hbase01:8093 1>kafka_connect_exporter.log.9002 2>&1 &
nohup kafka_connect_exporter-linux-amd64 -listen-address :9003 -scrape-uri http://pro-hbase01:8184 1>kafka_connect_exporter.log.9003 2>&1 &

#pro-hbase02
nohup kafka_connect_exporter-linux-amd64 -listen-address :9001 -scrape-uri http://pro-hbase02:18181 1>kafka_connect_exporter.log.9001 2>&1 &
nohup kafka_connect_exporter-linux-amd64 -listen-address :9002 -scrape-uri http://pro-hbase02:18182 1>kafka_connect_exporter.log.9002 2>&1 &
nohup kafka_connect_exporter-linux-amd64 -listen-address :9004 -scrape-uri http://pro-hbase02:18184 1>kafka_connect_exporter.log.9004 2>&1 &

#pro-hbase03
nohup kafka_connect_exporter-linux-amd64 -listen-address :9001 -scrape-uri http://pro-hbase03:18181 1>kafka_connect_exporter.log.9001 2>&1 &
nohup kafka_connect_exporter-linux-amd64 -listen-address :9002 -scrape-uri http://pro-hbase03:18182 1>kafka_connect_exporter.log.9002 2>&1 &
nohup kafka_connect_exporter-linux-amd64 -listen-address :9003 -scrape-uri http://pro-hbase03:18183 1>kafka_connect_exporter.log.9003 2>&1 &
nohup kafka_connect_exporter-linux-amd64 -listen-address :9004 -scrape-uri http://pro-hbase03:18184 1>kafka_connect_exporter.log.9004 2>&1 &

nohup kafka_connect_exporter-linux-amd64 -listen-address :9002 -scrape-uri http://pro-hbase04:18182 1>kafka_connect_exporter.log.9002 2>&1 &
nohup kafka_connect_exporter-linux-amd64 -listen-address :9003 -scrape-uri http://pro-hbase04:18183 1>kafka_connect_exporter.log.9003 2>&1 &
nohup kafka_connect_exporter-linux-amd64 -listen-address :9004 -scrape-uri http://pro-hbase04:18184 1>kafka_connect_exporter.log.9003 2>&1 &

ansible all -m shell -a"netstat -nlap|grep :::9001"
ansible all -m shell -a"netstat -nlap|grep :::9002"
ansible all -m shell -a"netstat -nlap|grep :::9003"
ansible all -m shell -a"netstat -nlap|grep :::9004"

docker pull prom/prometheus
mkdir prometheus
file=prometheus/prometheus.yml
cat << \EOF > ${file}
global:
  scrape_interval:     10s
  evaluation_interval: 10s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ['localhost:9090']
        labels:
          instance: prometheus

  - job_name: kafka
    static_configs:
      - targets: ['1110.1110.1.62:9308']
        labels:
          instance: localhost

  - job_name: kafka2
    static_configs:
      - targets: ['1110.1110.1.62:9309']
        labels:
          instance: datawarehouse

  - job_name: flink
    static_configs:
      - targets: ['1110.1110.1.62:19999', '1110.1110.11.47:19999', '1110.1110.13.106:19999', '1110.1110.3.169:19999']

  - job_name: mysql-slave
    static_configs:
      - targets: ['1110.1110.1.62:9104']
        labels:
          instance: copytrading_slave
      - targets: ['1110.1110.1.62:9105']
        labels:
          instance: push_slave
      - targets: ['1110.1110.1.62:9106']
        labels:
          instance: wallet_slave
      - targets: ['1110.1110.1.62:9107']
        labels:
          instance: sam_slave

  - job_name: debezium
    static_configs:
      - targets: ['1110.1110.1.62:7071']
        labels:
          instance: str-mysql
      - targets: ['1110.1110.1.62:7072']
        labels:
          instance: str-postgre
      - targets: ['1110.1110.1.62:7073']
        labels:
          instance: dw-mysql
      - targets: ['1110.1110.13.106:7074']
        labels:
          instance: dw-mg-src-src
      - targets: ['1110.1110.3.169:7075']
        labels:
          instance: dw-mg-dst-src

  - job_name: connector
    static_configs:
      - targets: ['1110.1110.1.62:9001']
        labels:
          instance: str-mysql
      - targets: ['1110.1110.1.62:9002']
        labels:
          instance: str-postgre
      - targets: ['1110.1110.1.62:9003']
        labels:
          instance: dw-mysql
      - targets: ['1110.1110.11.47:9001']
        labels:
          instance: dw-02-18181
      - targets: ['1110.1110.11.47:9002']
        labels:
          instance: dw-02-18182
      - targets: ['1110.1110.11.47:9004']
        labels:
          instance: dw-02-18184
      - targets: ['1110.1110.13.106:9001']
        labels:
          instance: dw-03-18181
      - targets: ['1110.1110.13.106:9002']
        labels:
          instance: dw-03-18182
      - targets: ['1110.1110.13.106:9003']
        labels:
          instance: dw-03-18183
      - targets: ['1110.1110.13.106:9004']
        labels:
          instance: dw-03-18184
      - targets: ['1110.1110.3.169:9002']
        labels:
          instance: dw-04-18182
      - targets: ['1110.1110.3.169:9003']
        labels:
          instance: dw-04-18183
      - targets: ['1110.1110.3.169:9004']
        labels:
          instance: dw-04-18184
EOF

docker run -itd -p 9390:9090 --name prometheus -v /app/hadoop/prometheus:/data prom/prometheus --config.file=/data/prometheus.yml
netstat -nlap|grep 9390

docker pull grafana/grafana
mkdir grafana
sudo rm -rf /app/hadoop/grafana/*
docker run -itd -p 3000:3000 --name=grafana -v /app/hadoop/grafana:/var/lib/grafana grafana/grafana
docker cp grafana:/etc/grafana/grafana.ini ./
sed -i '/;startTLS_policy = NoStartTLS/a\
enabled = true \
host = smtp.163.com:465 \
user = bronzels@163.com \
password = XXXXXX \
skip_verify = true \
from_address = bronzels@163.com \
from_name = Grafana' grafana.ini
docker cp ./grafana.ini grafana:/etc/grafana/grafana.ini
sudo chmod -R 777 /app/hadoop/grafana
netstat -nlap|grep 3000
docker exec -it grafana bash
  #cd /usr/share/grafana/bin
  #./grafana-cli admin reset-admin-password bd123456



#mongodb客户端安装
#root
wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1804-4.0.14.tgz
tar -zxvf mongodb-linux-x86_64-ubuntu1804-4.0.14.tgz
cp -r mongodb-linux-x86_64-ubuntu1804-4.0.14 /usr/local/mongodb
echo "export PATH=$PATH:/usr/local/mongodb/bin" >> other-env.sh
source ~/.bashrc




#其他master上部署相关目录脚本
sed -i 's@1110.111.0.11:3333@1110.1110.5.250:3306@g' ~/scripts/sqoop_import_all_mysql_dump_tradebatch.sh
#从pro-hbase05上copy sam的脚本
scp ~/scripts/sqoop_import_all_mysql_dump_tradebatch_sam.sh hadoop@1110.1110.1.62:/app/hadoop/scripts/
sed -i 's@1110.110.0.244:3307@1110.1110.5.250:3309@g' ~/scripts/sqoop_import_all_mysql_dump_tradebatch_sam.sh
#从pro-hbase01上copy 流处理启动脚本
scp ~/fm/str/startfmstrall.sh hadoop@1110.1110.1.62:/app/hadoop/fm/str/
mkdir -p fm/jar
mkdir -p fm/str
mkdir -p fm/to_release/jar
mkdir fm_sensorsdata
mkdir deploy
#从beta-hbase01上copy deploy脚本
scp deploy/deploy_spark_jars.sh hadoop@1110.1110.1.62:/app/hadoop/deploy
scp deploy/deploy_jar_jars.sh hadoop@1110.1110.1.62:/app/hadoop/deploy
chmod a+x ~/deploy/*.sh
echo "export PATH=${PATH}:/app/hadoop/venvs/airflow/bin" >> ~/other-env.sh



