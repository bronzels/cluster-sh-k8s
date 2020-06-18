#root
#安装ntp
ansible all -m shell -a"apt-get install -y ntp"
#开机自启动
ansible all -m shell -a"systemctl enable ntp"
cat << \EOF > /etc/ntp.conf
sudo vim /etc/ntp.conf
driftfile  /var/lib/ntp/drift
pidfile   /var/run/ntpd.pid
logfile /var/log/ntp.log
restrict    default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery
restrict 127.0.0.1
server 127.127.1.0
fudge  127.127.1.0 stratum 10
server ntp.aliyun.com iburst minpoll 4 maxpoll 10
restrict ntp.aliyun.com nomodify notrap nopeer noquery
EOF
ansible allexpcp -m copy -a"src=/etc/ntp.conf dest=/etc"

#添加cloudera仓库
ansible all -m shell -a"curl -s https://archive.cloudera.com/cm6/6.3.1/ubuntu1604/apt/archive.key | apt-key add -"
wget https://archive.cloudera.com/cm6/6.3.1/ubuntu1804/apt/cloudera-manager.list
ansible all -m copy -a"src=~/cloudera-manager.list dest=/etc/apt/sources.list.d/"
apt-get update

#安装JAVA
ansible all -m shell -a"apt-get install -y openjdk-8-jdk"
ansible all -m shell -a"java -version"

mkdir -p ~/cdh/deb
cd ~/cdh/deb
wget -c https://archive.cloudera.com/cm6/6.3.1/ubuntu1804/apt/pool/contrib/e/enterprise/cloudera-manager-agent_6.3.1~1466458.ubuntu1804_amd64.deb
wget -c https://archive.cloudera.com/cm6/6.3.1/ubuntu1804/apt/pool/contrib/e/enterprise/cloudera-manager-daemons_6.3.1~1466458.ubuntu1804_all.deb
wget -c https://archive.cloudera.com/cm6/6.3.1/ubuntu1804/apt/pool/contrib/e/enterprise/cloudera-manager-server-db-2_6.3.1~1466458.ubuntu1804_all.deb
wget -c https://archive.cloudera.com/cm6/6.3.1/ubuntu1804/apt/pool/contrib/e/enterprise/cloudera-manager-server-db_6.3.1~1466458.ubuntu1804_all.deb
wget -c https://archive.cloudera.com/cm6/6.3.1/ubuntu1804/apt/pool/contrib/e/enterprise/cloudera-manager-server_6.3.1~1466458.ubuntu1804_all.deb
ansible all -m copy -a"src=~/cdh/cloudera-manager-agent_6.3.1~1466458.ubuntu1804_amd64.deb dest=/var/cache/apt/archives/"
ansible all -m copy -a"src=~/cdh/cloudera-manager-daemons_6.3.1~1466458.ubuntu1804_all.deb dest=/var/cache/apt/archives/"
ansible all -m copy -a"src=~/cdh/cloudera-manager-server-db-2_6.3.1~1466458.ubuntu1804_all.deb dest=/var/cache/apt/archives/"
ansible all -m copy -a"src=~/cdh/cloudera-manager-server-db_6.3.1~1466458.ubuntu1804_all.deb dest=/var/cache/apt/archives/"
ansible all -m copy -a"src=~/cdh/cloudera-manager-server_6.3.1~1466458.ubuntu1804_all.deb dest=/var/cache/apt/archives/"
ansible all -m shell -a"ls -l /var/cache/apt/archives/cloudera-manager*"

mkdir -p ~/cdh/parcel
cd ~/cdh/parcel
wget -c https://archive.cloudera.com/cdh6/6.3.2/parcels/CDH-6.3.2-1.cdh6.3.2.p0.1605554-bionic.parcel
wget -c https://archive.cloudera.com/cdh6/6.3.2/parcels/CDH-6.3.2-1.cdh6.3.2.p0.1605554-bionic.parcel.sha1
wget -c https://archive.cloudera.com/cdh6/6.3.2/parcels/manifest.json
mv CDH-6.3.2-1.cdh6.3.2.p0.1605554-bionic.parcel.sha1 CDH-6.3.2-1.cdh6.3.2.p0.1605554-bionic.parcel.sha
ansible all -m shell -a"mkdir -p /opt/cloudera/parcel-repo"
ansible all -m copy -a"src=CDH-6.3.2-1.cdh6.3.2.p0.1605554-bionic.parcel dest=/opt/cloudera/parcel-repo"
ansible all -m copy -a"src=CDH-6.3.2-1.cdh6.3.2.p0.1605554-bionic.parcel.sha dest=/opt/cloudera/parcel-repo"
ansible all -m copy -a"src=manifest.json dest=/opt/cloudera/parcel-repo"
ansible all -m shell -a"ls -l /opt/cloudera/parcel-repo"


#启动docker mysql实例cdh使用
cd
mkdir /var/lib/mysql
rm -rf /var/lib/mysql/*
docker run --name=mysql_cdh \
-p 3306:3306 \
-e MYSQL_ROOT_PASSWORD=root \
-v /var/lib/mysql:/var/lib/mysql \
-d mysql:5.7
#！！！手工，登录修改mysql root密码
apt-get install -y mysql-client
docker ps|grep mysql
docker exec -it c5b14bb01813 bash
  mysql -P3306 -uroot -proot
      FLUSH PRIVILEGES;
      USE mysql;
      ALTER USER 'root'@'%' IDENTIFIED BY 'root';
      GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION;
      FLUSH PRIVILEGES;
mysql -h master01 -P3306 -uroot -proot -e "SHOW DATABASES"

cd ~/cdh
cat << \EOF > db.sql
-- 创建数据库
-- Cloudera Manager Server
CREATE DATABASE scm DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
-- Activity Monitor
CREATE DATABASE amon DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
-- Reports Manager
CREATE DATABASE rman DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
-- Hue
CREATE DATABASE hue DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
-- Hive Metastore Server
CREATE DATABASE hive DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
-- Sentry Server
CREATE DATABASE sentry DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
-- Cloudera Navigator Audit Server
CREATE DATABASE nav DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
-- Cloudera Navigator Metadata Server
CREATE DATABASE navms DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
-- Oozie
CREATE DATABASE oozie DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
 
-- 创建用户并授权
GRANT ALL ON scm.* TO 'scm'@'%' IDENTIFIED BY 'scm';
GRANT ALL ON amon.* TO 'amon'@'%' IDENTIFIED BY 'amon';
GRANT ALL ON rman.* TO 'rman'@'%' IDENTIFIED BY 'rman';
GRANT ALL ON hue.* TO 'hue'@'%' IDENTIFIED BY 'hue';
GRANT ALL ON hive.* TO 'hive'@'%' IDENTIFIED BY 'hive';
GRANT ALL ON sentry.* TO 'sentry'@'%' IDENTIFIED BY 'sentry';
GRANT ALL ON nav.* TO 'nav'@'%' IDENTIFIED BY 'nav';
GRANT ALL ON navms.* TO 'navms'@'%' IDENTIFIED BY 'navms';
GRANT ALL ON oozie.* TO 'oozie'@'%' IDENTIFIED BY 'oozie';
EOF

mysql -h master01 -P3306 -uroot -proot -Dmysql < ./db.sql
mysql -h master01 -P3306 -uroot -proot -e "SHOW DATABASES"

ansible all -m shell -a"apt-get install -yq cloudera-manager-daemons cloudera-manager-agent cloudera-manager-server"

wget -c https://cdn.mysql.com//archives/mysql-connector-java-5.1/mysql-connector-java-5.1.46.tar.gz
tar xzvf mysql-connector-java-5.1.46.tar.gz
mysql-connector-java-5.1.46.jar
cp mysql-connector-java-5.1.46/mysql-connector-java-5.1.46.jar mysql-connector-java.jar
ansible all -m copy -a"src=mysql-connector-java.jar dest=/opt/cloudera/cm/schema/../lib/"
ansible all -m shell -a"ls -l /opt/cloudera/cm/schema/../lib/mysql-connector-java.jar"
ansible all -m copy -a"src=mysql-connector-java.jar dest=/usr/share/java"

/opt/cloudera/cm/schema/scm_prepare_database.sh mysql scm scm scm
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql amon amon amon
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql rman rman rman
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql hue hue hue
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql hive hive hive
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql sentry sentry sentry
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql nav nav nav
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql navms navms navms
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql oozie oozie oozie

file=/etc/cloudera-scm-agent/config.ini
cp ${file} ${file}.bk
sed -i 's@server_host=localhost@server_host=master01@g' ${file}
ansible allexpcp -m copy -a"src=/etc/cloudera-scm-agent/config.ini dest=/etc/cloudera-scm-agent"

systemctl start cloudera-scm-server
tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log

ansible slave -m shell -a"systemctl start cloudera-scm-agent"
ansible slave -m shell -a"tail -100 /var/log/cloudera-scm-agent/cloudera-scm-agent.log"

:<<EOF
访问cloudera-manager
浏览器输入http://master01:7180/
用户/密码：admin/admin
按照向导搭建集群。
有问题查看日志解决
EOF