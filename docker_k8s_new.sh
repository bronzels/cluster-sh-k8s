#master
#root

# step 1: 安装必要的一些系统工具
ansible newgrp -m shell -a"apt-get update"
ansible newgrp -m shell -a"apt-get -y install apt-transport-https ca-certificates curl software-properties-common"
# step 2: 安装GPG证书
ansible newgrp -m shell -a"gpg --keyserver keyserver.ubuntu.com --recv 7EA0A9C3F273FCD8"
ansible newgrp -m shell -a"gpg --export --armor 7EA0A9C3F273FCD8  | apt-key add -"
ansible newgrp -m shell -a"curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | apt-key add -"
# Step 3: 写入软件源信息
ansible newgrp -m shell -a'add-apt-repository "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"'
# Step 4: 更新并安装 Docker-CE
ansible newgrp -m shell -a"apt-get -y update"
ansible newgrp -m shell -a"curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun"

ansible newgrp -m shell -a"docker --version"
ansible newgrp -m shell -a"systemctl enable docker.service"
ansible newgrp -m copy -a"src=/etc/docker/daemon.json dest=/etc/docker"
ansible newgrp -m shell -a"systemctl daemon-reload"
ansible newgrp -m shell -a"systemctl restart docker"

ansible newgrp -m shell -a"ufw disable"
ansible newgrp -m shell -a"apt install -y selinux-utils"
ansible newgrp -m shell -a"swapoff -a"
ansible newgrp -m shell -a"setenforce 0"

ansible newgrp -m shell -a"mkdir /etc/sysconfig"
ansible newgrp -m copy -a"src=/etc/sysconfig/selinux dest=/etc/sysconfig"

ansible newgrp -m shell -a"rm -rf /etc/sysconfig/modules/;mkdir -p /etc/sysconfig/modules/"
ansible newgrp -m copy -a"src=/etc/sysctl.d/k8s-sysctl.conf dest=/etc/sysctl.d"
ansible newgrp -m shell -a"sysctl -p /etc/sysctl.d/k8s-sysctl.conf"

ansible newgrp -m shell -a"curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -"
ansible newgrp -m copy -a"src=/etc/apt/sources.list.d/kubernetes.list dest=/etc/apt/sources.list.d"
ansible newgrp -m shell -a"apt-get update"
ansible newgrp -m shell -a"apt-get install -y kubelet kubeadm kubectl"
ansible newgrp -m shell -a"kubeadm reset -f"
ansible newgrp -m shell -a"systemctl enable kubelet"
