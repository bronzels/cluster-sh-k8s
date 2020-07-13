sudo su -
#root
ansible all -m shell -a"cat /etc/issue"
ansible all -m shell -a"uname -r"
ansible all -m shell -a"free -g"

ansible hk-prod-bigdata-master-8-148,hk-prod-bigdata-slave-1-62,hk-prod-bigdata-slave-11-47,hk-prod-bigdata-slave-13-106,hk-prod-bigdata-slave-3-169 -m shell -a"cp /etc/hosts /etc/hosts.bk"
ansible hk-prod-bigdata-master-8-148,hk-prod-bigdata-slave-1-62,hk-prod-bigdata-slave-11-47,hk-prod-bigdata-slave-13-106,hk-prod-bigdata-slave-3-169 -m copy -a"src=/etc/hosts dest=/etc"

ansible all -m shell -a"cat /etc/hosts"
ansible all -m shell -a"ip addr|grep 1110.1110."

#used for nfs mount in deployment yaml
ansible all -m shell -a"apt install -y nfs-common"

exit
#ubuntu
#scripts for airflow to ssh and execute, or for manual op
mkdir ~/scripts/

#folder by backup released packages
mkdir ~/released/

#env scripts path set
echo "export PATH=$PATH:$HOME/scripts" >> ~/other-env.sh
#env scripts sourced in .bashrc
echo "source ${HOME}/other-env.sh" >> ~/.bashrc
source ~/.bashrc

rev=1.12.9
wget -c https://dl.google.com/go/go${rev}.linux-amd64.tar.gz
rm -rf go
tar -C ~ -xzf ~/go${rev}.linux-amd64.tar.gz

#ubuntu
#for flink native on k8s
#apt-get install -y openjdk-8-jdk
rev=241
cd
tar xzvf /tmp/jdk-8u${rev}-linux-x64.tar.gz
rm -f jdk
ln -s jdk1.8.0_${rev} jdk
echo "export JAVA_HOME=$HOME/jdk" >> ~/other-env.sh
echo "export PATH=$HOME/jdk/bin:$PATH" >> ~/other-env.sh
source ~/.bashrc
java -version

#for airflow dags mouting, and later other use as well
mkdir ${HOME}/nfsmnt
:<<EOF
docker run -d -p 2049:2049 --name mynfs --privileged -v ${HOME}/nfsmnt:/nfsshare -e SHARED_DIRECTORY=/nfsshare itsthenetwork/nfs-server-alpine:latest
mkdir ${HOME}/nfsmnted
sudo mount -v -o vers=4,loud 1110.1110.9.83:/ ~/nfsmnted
touch ~/nfsmnt/x
ls ~/nfsmnted
sudo umount ~/nfsmnted
EOF

#for airflow image building
mkdir ~/.pip
cat << \EOF > ~/.pip/pip.conf
[global]
index-url = https://mirrors.aliyun.com/pypi/simple
[install]
trusted-host=mirrors.aliyun.com
EOF

#for kubernetes yaml manupulation
sudo apt install python-pip -yqq
sudo pip install yq
#used in postgre scripts
sudo pip install y2j

#for hive/db-tools building
wget -c https://services.gradle.org/distributions/gradle-4.10.2-bin.zip
unzip gradle-4.10.2-bin.zip
ln -s gradle-4.10.2 gradle
echo "export GRADLE_HOME=${HOME}/gradle" >> other-env.sh
echo "export PATH=$PATH:${HOME}/gradle/bin" >> other-env.sh
source ~/.bashrc
gradle --version

#run docker in ubuntu,for chartmesum docker setup
sudo gpasswd -a $USER docker
newgrp docker

