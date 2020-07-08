#root
#安装ntp
ansible allcdh -m shell -a"apt-get install -y ntp"
#开机自启动
ansible allcdh -m shell -a"systemctl enable ntp"
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
ansible slavecdh -m copy -a"src=/etc/ntp.conf dest=/etc"

#安装JAVA
ansible allcdh -m shell -a"apt-get install -y openjdk-8-jdk"
#presto要求jdk版本8u151+
ansible allcdh -m shell -a"java -version"
echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> ~/other-env.sh



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
docker exec -it `docker ps  |grep mysql_cdh | awk '{print $1}'` bash
  mysql -P3306 -uroot -proot
      FLUSH PRIVILEGES;
      USE mysql;
      ALTER USER 'root'@'%' IDENTIFIED BY 'root';
      GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION;
      FLUSH PRIVILEGES;
mysql -h 10.10.0.31 -P3306 -uroot -proot -e "SHOW DATABASES"

mkdir ~/cdh
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

mysql -h 10.10.0.31 -P3306 -uroot -proot -Dmysql < ./db.sql
mysql -h 10.10.0.31 -P3306 -uroot -proot -e "SHOW DATABASES"

cd ~/cdh
wget -c https://cdn.mysql.com//archives/mysql-connector-java-5.1/mysql-connector-java-5.1.46.tar.gz
tar xzvf mysql-connector-java-5.1.46.tar.gz
cp mysql-connector-java-5.1.46/mysql-connector-java-5.1.46.jar mysql-connector-java.jar
ansible allcdh -m copy -a"src=~/cdh/mysql-connector-java.jar dest=/usr/share/java"
ansible allcdh -m shell -a"ls -l /usr/share/java/mysql-connector-java.jar"
#ansible allcdh -m copy -a"src=mysql-connector-java.jar dest=/opt/cloudera/cm/schema/../lib/"
#ansible allcdh -m shell -a"ls -l /opt/cloudera/cm/schema/../lib/mysql-connector-java.jar"

