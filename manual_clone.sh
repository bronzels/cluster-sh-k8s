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
mkdir /app1
mount /dev/nvme0n1p1 /app1
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

#创建hadoop用户，home目录，设置pwd
useradd -d /app/hadoop -m hadoop
usermod --password $(echo hadoop | openssl passwd -1 -stdin) hadoop

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

10.10.1.62 pro-hbase01
10.10.11.47 pro-hbase02
10.10.13.106 pro-hbase03
10.10.3.169 pro-hbase04
cat <<EOF >> /etc/hosts

10.10.1.62 hk-prod-bigdata-slave-1-62
10.10.11.47 hk-prod-bigdata-slave-11-47
10.10.13.106 hk-prod-bigdata-slave-13-106
10.10.3.169 hk-prod-bigdata-slave-3-169

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


ansible slave -m copy -a"src=/etc/hosts dest=/etc"

ansible all -m shell -a"chown -R hadoop:hadoop /app"
ansible all -m shell -a"chown -R hadoop:hadoop /app2"

#给hadoop设置sudo
ansible slave -m shell -a"cp /etc/sudoers /etc/sudoers.bk"
ansible slave -m copy -a"src=/etc/sudoers dest=/etc"

#给hadoop设置bash
ansible slave -m shell -a"cp /etc/passwd /etc/passwd.bk"
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
10.10.1.62 hk-prod-bigdata-slave-1-62
10.10.11.47 hk-prod-bigdata-slave-11-47
10.10.13.106 hk-prod-bigdata-slave-13-106
10.10.3.169 hk-prod-bigdata-slave-3-169
EOF

#全程替换 scripts配置
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd ~/scripts;ls|xargs grep beta-hbase0"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd ~/scripts;ls|xargs sed -i 's@beta-hbase0@pro-hbase0@g'"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd ~/scripts;ls|xargs grep pro-hbase0"



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
scp /app/home/hadoop/hadoop/etc/hadoop/fair-scheduler.xml hadoop@10.10.1.62:/app/hadoop/hadoop/etc/hadoop/fair-scheduler.xml
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"rm -rf /app/data/hadoop/hdfs/journaldata/*"
hdfs --workers --daemon start journalnode
#hdfs --workers --daemon stop journalnode
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"jps"
hdfs zkfc -formatZK
hdfs namenode -format
hdfs --daemon start namenode
#hdfs --daemon stop namenode
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
rm -rf /app/docker/mysql/hive/*
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
      ALTER USER 'hive'@'%' IDENTIFIED BY 'hive';
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
scp hbase.tgz hadoop@10.10.1.62:/app/hadoop/
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
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"jps"



#全程替换 kylin配置
#从beta-hbase01 打包copy kylin和软连接
ansible all -m shell -a"cd /app/hadoop;rm -rf apache-kylin-3.0.1-bin-hadoop3 kylin;ls -l"
tar czvf kylin.tgz apache-kylin-3.0.1-bin-hadoop3 kylin --exclude=apache-kylin-3.0.1-bin-hadoop3/logs
scp kylin.tgz hadoop@10.10.1.62:/app/hadoop/
tar xzvf kylin.tgz
cat << \EOF >> kylin/conf/kylin.properties
kylin.web.query-timeout=3000000
kylin.source.hive.keep-flat-table=true
kylin.source.hive.quote-enabled=false
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
scp -r  /app/hadoop/kudu/config/master.gflagfile hadoop@10.10.1.62:/app/hadoop/kudu/config/master.gflagfile
scp -r  /app/hadoop/kudu/config/tserver.gflagfile hadoop@10.10.1.62:/app/hadoop/kudu/config/tserver.gflagfile
cd /app/hadoop/kudu/config;
find * | xargs grep beta-hbase0
find * | xargs sed -i 's@beta-hbase0@pro-hbase0@g'
find * | xargs grep beta-hbase0
find * | xargs grep pro-hbase0
find * | xargs grep 10.1.0.11
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
ansible all -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs grep beta-hbase0"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs sed -i 's@beta-hbase0@pro-hbase0@g'"
ansible all -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs grep beta-hbase0"
ansible all -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs grep pro-hbase0"

ansible all -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs grep 10.1.0.11"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs sed -i 's@10.1.0.11@10.10.1.62@g'"
ansible all -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs grep 10.1.0.11"
ansible all -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs grep 10.10.1.62"


ansible all -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs grep 10.1.0.12"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs sed -i 's@10.1.0.12@10.10.11.47@g'"
ansible all -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs grep 10.1.0.12"
ansible all -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs grep 10.10.11.47"

ansible all -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs grep 10.1.0.13"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs sed -i 's@10.1.0.13@10.10.13.106@g'"
ansible all -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs grep 10.1.0.13"
ansible all -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs grep 10.10.13.106"

ansible all -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs grep 10.1.0.14"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs sed -i 's@10.1.0.14@10.10.3.169@g'"
ansible all -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs grep 10.1.0.14"
ansible all -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs grep 10.10.3.169"

ansible all -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs grep beta_test"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs sed -i 's@beta_test@pro_test@g'"
ansible all -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs grep beta_test"
ansible all -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs grep pro_test"

mykafka1_server.sh start
mykafka1_server.sh status
mykafka1_produce.sh test
mykafka1_consume.sh test from-beginning

mykafka2_server.sh start
mykafka2_server.sh status
mykafka2_produce.sh test
mykafka2_consume.sh test from-beginning



#全程替换 presto配置
ansible all -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs grep beta-hbase0"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd /app/hadoop/presto-server/etc;find * -type f | xargs sed -i 's@beta-hbase0@pro-hbase0@g'"
ansible all -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs grep beta-hbase0"
ansible all -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs grep pro-hbase0"

ansible all -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs grep pro-hbase05"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"cd /app/hadoop/presto-server/etc;find * -type f | xargs sed -i 's@pro-hbase05@pro-hbase01@g'"
ansible all -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs grep pro-hbase05"
ansible all -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs grep pro-hbase06"


ansible all -m shell -a"cd /app/hadoop/presto-server/etc;find * | xargs grep 10.1.0.11"
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
scp pika/conf/pika.conf hadoop@10.10.1.62:/app/hadoop/pika/conf
scp pika/conf/pika_yat.conf hadoop@10.10.1.62:/app/hadoop/pika/conf

find * | xargs grep beta-hbase0
find * | xargs grep 10.1.0.11
find * | xargs grep 10.1.0.12

cd ~
tar czvf pika.tgz pika
ansible slave -m copy -a"src=/app/hadoop/pika.tgz dest=/app/hadoop"
ansible slave -m shell -a"cd /app/hadoop;tar xzvf pika.tgz;rm -f pika.tgz"

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
scp -r /app/hadoop/gopath/src/github.com/CodisLabs/codis/ansible hadoop@10.10.1.62:/app/hadoop/gopath/src/github.com/CodisLabs/codis/
scp -r /app/hadoop/gopath/src/github.com/CodisLabs/codis/ansible_yat hadoop@10.10.1.62:/app/hadoop/gopath/src/github.com/CodisLabs/codis/
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
scp opentsdb.tgz hadoop@10.10.1.62:/app/hadoop/
tar xzvf opentsdb.tgz

grep "2181" ~/opentsdb/src/opentsdb_tmp.conf
sed -i 's@tsd.storage.hbase.zk_quorum = beta-hbase02:2281,beta-hbase03:2281,beta-hbase04:2281@tsd.storage.hbase.zk_quorum = 10.10.20.191:2181@g' ~/opentsdb/src/opentsdb_tmp.conf
grep "2181" ~/opentsdb/src/opentsdb_tmp.conf
grep "/hbase" ~/opentsdb/src/opentsdb_tmp.conf
sed -i 's@tsd.storage.hbase.zk_basedir = /hbase1@tsd.storage.hbase.zk_basedir = /hbase@g' ~/opentsdb/src/opentsdb_tmp.conf
grep "/hbase" ~/opentsdb/src/opentsdb_tmp.conf
mkdir opentsdb/log
tar czvf opentsdb.tgz opentsdb
ansible slave -m copy -a"src=/app/hadoop/opentsdb.tgz dest=/app/hadoop"
ansible slave -m shell -a"cd /app/hadoop;tar xzvf opentsdb.tgz;rm -f opentsdb.tgz"
curl -ki -X POST -d '{"metric":"testdata", "timestamp":1524900185000, "value":9999.99, "tags":{"key":"value"}}' http://10.10.11.47:4344/api/put?sync
curl  -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://10.10.11.47:4344/api/query  -d '
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




#建立master上和部署有关目录
mkdir -p fm/sql
mkdir -p fm/jar
mkdir -p fm/to_release
mkdir fm_sensorsdata
mkdir deploy

