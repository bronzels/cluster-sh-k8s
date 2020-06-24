#root
cd
#添加cloudera仓库
ansible allcdh -m shell -a"curl -s https://archive.cloudera.com/cm6/6.3.1/ubuntu1604/apt/archive.key | apt-key add -"
wget https://archive.cloudera.com/cm6/6.3.1/ubuntu1804/apt/cloudera-manager.list
ansible allcdh -m copy -a"src=~/cloudera-manager.list dest=/etc/apt/sources.list.d/"
ansible allcdh -m shell -a"apt-get update"

mkdir -p ~/cdh/deb
cd ~/cdh/deb
wget -c https://archive.cloudera.com/cm6/6.3.1/ubuntu1804/apt/pool/contrib/e/enterprise/cloudera-manager-agent_6.3.1~1466458.ubuntu1804_amd64.deb
wget -c https://archive.cloudera.com/cm6/6.3.1/ubuntu1804/apt/pool/contrib/e/enterprise/cloudera-manager-daemons_6.3.1~1466458.ubuntu1804_all.deb
wget -c https://archive.cloudera.com/cm6/6.3.1/ubuntu1804/apt/pool/contrib/e/enterprise/cloudera-manager-server-db-2_6.3.1~1466458.ubuntu1804_all.deb
wget -c https://archive.cloudera.com/cm6/6.3.1/ubuntu1804/apt/pool/contrib/e/enterprise/cloudera-manager-server-db_6.3.1~1466458.ubuntu1804_all.deb
wget -c https://archive.cloudera.com/cm6/6.3.1/ubuntu1804/apt/pool/contrib/e/enterprise/cloudera-manager-server_6.3.1~1466458.ubuntu1804_all.deb
ansible allcdh -m copy -a"src=~/cdh/deb/cloudera-manager-agent_6.3.1~1466458.ubuntu1804_amd64.deb dest=/var/cache/apt/archives/"
ansible allcdh -m copy -a"src=~/cdh/deb/cloudera-manager-daemons_6.3.1~1466458.ubuntu1804_all.deb dest=/var/cache/apt/archives/"
ansible allcdh -m copy -a"src=~/cdh/deb/cloudera-manager-server-db-2_6.3.1~1466458.ubuntu1804_all.deb dest=/var/cache/apt/archives/"
ansible allcdh -m copy -a"src=~/cdh/deb/cloudera-manager-server-db_6.3.1~1466458.ubuntu1804_all.deb dest=/var/cache/apt/archives/"
ansible allcdh -m copy -a"src=~/cdh/deb/cloudera-manager-server_6.3.1~1466458.ubuntu1804_all.deb dest=/var/cache/apt/archives/"
ansible allcdh -m shell -a"ls -l /var/cache/apt/archives/cloudera-manager*"

mkdir -p ~/cdh/parcel
cd ~/cdh/parcel
wget -c https://archive.cloudera.com/cdh6/6.3.2/parcels/CDH-6.3.2-1.cdh6.3.2.p0.1605554-bionic.parcel
wget -c https://archive.cloudera.com/cdh6/6.3.2/parcels/CDH-6.3.2-1.cdh6.3.2.p0.1605554-bionic.parcel.sha1
wget -c https://archive.cloudera.com/cdh6/6.3.2/parcels/manifest.json
mv CDH-6.3.2-1.cdh6.3.2.p0.1605554-bionic.parcel.sha1 CDH-6.3.2-1.cdh6.3.2.p0.1605554-bionic.parcel.sha
ansible allcdh -m shell -a"mkdir -p /opt/cloudera/parcel-repo"
ansible allcdh -m copy -a"src=CDH-6.3.2-1.cdh6.3.2.p0.1605554-bionic.parcel dest=/opt/cloudera/parcel-repo"
ansible allcdh -m copy -a"src=CDH-6.3.2-1.cdh6.3.2.p0.1605554-bionic.parcel.sha dest=/opt/cloudera/parcel-repo"
ansible allcdh -m copy -a"src=manifest.json dest=/opt/cloudera/parcel-repo"
ansible allcdh -m shell -a"ls -l /opt/cloudera/parcel-repo"

#！！！手工，重新登录root
