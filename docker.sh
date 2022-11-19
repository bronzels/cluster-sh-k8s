sudo su -
#root
#ubuntu
# step 1: 安装必要的一些系统工具
ansible allk8s -m shell -a"apt-get update"
ansible allk8s -m shell -a"apt-get -y install apt-transport-https ca-certificates curl software-properties-common"
# step 2: 安装GPG证书
ansible allk8s -m shell -a"gpg --keyserver keyserver.ubuntu.com --recv 7EA0A9C3F273FCD8"
ansible allk8s -m shell -a"gpg --export --armor 7EA0A9C3F273FCD8  | apt-key add -"
ansible allk8s -m shell -a"curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | apt-key add -"
# Step 3: 写入软件源信息
ansible allk8s -m shell -a'add-apt-repository "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"'
# Step 4: 更新并安装 Docker-CE
ansible allk8s -m shell -a"apt-get -y update"
ansible allk8s -m shell -a"curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun"
#ubuntu 16
apt-get install docker-ce=5:20.10.7~3-0~ubuntu-xenial
#ubuntu 18
#apt-get install -y docker-ce=5:20.10.7~3-0~ubuntu-bionic
apt-get install -y docker-ce=5:20.10.18~3-0~ubuntu-bionic docker-ce-cli=5:20.10.18~3-0~ubuntu-bionic containerd.io docker-compose-plugin
#apt-get autoremove docker docker-ce docker-ce-cli docker-engine docker.io containerd runc
#19.03.8

#centos
yum-config-manager \
--add-repo \
http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum install -y docker-ce-20.10.18
#yum remove containerd.io.x86_64 docker-ce.x86_64 docker-ce-cli.x86_64 docker-ce-rootless-extras.x86_64 docker-scan-plugin.x86_64


ansible allk8s -m shell -a"docker --version"
ansible allk8s -m shell -a"systemctl enable docker.service"

#root
:<<EOF
  "dns": ["8.8.8.8", "114.114.114.114"]
  "dns": ["8.8.8.8", "8.8.4.4"]
  "iptables": false,
关闭iptables会导致build image在apt-get update时失败，提示Could not resolve 'archive.ubuntu.com'
最初关闭iptables，是因为据说：数据包经过路由后，假如不是发往本机的流量，下一步会走iptables的FORWARD链，而docker从1.13版本开始，将FORWARD链的默认策略设置为DROP，会导致出现一些例如跨主机的两个pod使用podIP互访失败等问题。
设置docker启动参数添加--iptables=false选项，使docker不再操作iptabl。
EOF
cat << EOF > /etc/docker/daemon.json
{
  "registry-mirrors": [
  "https://xxxxxx.mirror.aliyuncs.com",
  "http://hub-mirror.c.163.com"
  ],
  "insecure-registries":["harbor.my.org:1080"],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "data-root": "/data0/docker"
}
EOF
ansible allk8sexpcp -m copy -a"src=/etc/docker/daemon.json dest=/etc/docker"
ansible allk8s -m shell -a"cat /etc/docker/daemon.json"

ansible allk8s -m shell -a"systemctl daemon-reload"
ansible allk8s -m shell -a"systemctl restart docker"
ansible allk8s -m shell -a"systemctl enable docker"
systemctl daemon-reload
systemctl enable docker
systemctl restart docker

#设置sudo
#ubuntu
#ansible allk8s -i /etc/ansible/hosts-ubuntu -m shell -a"sudo gpasswd -a $USER docker"
#ansible allk8s -i /etc/ansible/hosts-ubuntu -m shell -a"newgrp docker"
sudo gpasswd -a $USER docker
newgrp docker
ll /var/run/docker.sock
sudo chgrp docker /var/run/docker.sock
ll /var/run/docker.sock
#chown root:docker /var/run/docker.sock

rm -rf /data0/docker/*
rm -rf /var/lib/containerd
rm -rf /var/lib/docker
