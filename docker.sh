#root
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
#19.03.8
ansible allk8s -m shell -a"docker --version"
ansible allk8s -m shell -a"systemctl enable docker.service"
#root
cat << EOF > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "iptables": false,
  "insecure-registries":["master01:30500"]
}
EOF
ansible allk8sexpcp -m copy -a"src=/etc/docker/daemon.json dest=/etc/docker"
ansible allk8s -m shell -a"cat /etc/docker/daemon.json"
ansible allk8s -m shell -a"systemctl daemon-reload"
ansible allk8s -m shell -a"systemctl restart docker"

#ubuntu
sudo gpasswd -a $USER docker
newgrp docker


