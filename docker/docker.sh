#！！！手工, 新机器加入集群跳过所有cat EOF文件生成步骤
#root
# step 1: 安装必要的一些系统工具
ansible all -m shell -a"apt-get update"
ansible all -m shell -a"apt-get -y install apt-transport-https ca-certificates curl software-properties-common"
# step 2: 安装GPG证书
ansible all -m shell -a"gpg --keyserver keyserver.ubuntu.com --recv 7EA0A9C3F273FCD8"
ansible all -m shell -a"gpg --export --armor 7EA0A9C3F273FCD8  | apt-key add -"
ansible all -m shell -a"curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | apt-key add -"
# Step 3: 写入软件源信息
ansible all -m shell -a'add-apt-repository "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"'
# Step 4: 更新并安装 Docker-CE
ansible all -m shell -a"apt-get -y update"
ansible all -m shell -a"curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun"
#19.03.8
ansible all -m shell -a"docker --version"
ansible all -m shell -a"systemctl enable docker.service"
cat << EOF > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "iptables": false,
  "insecure-registries":["master01:30500"]
}
EOF
ansible allexpcp -m copy -a"src=/etc/docker/daemon.json dest=/etc/docker"
ansible all -m shell -a"cat /etc/docker/daemon.json"
ansible all -m shell -a"systemctl daemon-reload"
ansible all -m shell -a"systemctl restart docker"

#ubuntu
sudo gpasswd -a $USER docker
newgrp docker


