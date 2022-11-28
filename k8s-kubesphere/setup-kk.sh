#worker
#centos
#时间同步
date
systemctl status chronyd
#sudo权限
sudo ls /
#解压缩
yum install -y curl tar zip unzip
#docker以外容器运行时状态
systemctl status containerd
#网络工具包
yum install -y epel-release
yum install -y socat conntrack-tools ebtables ipset ipvsadm nfs-utils
#dns解析
cat /etc/resolv.conf
cat >> /etc/resolv.conf << EOF
nameserver 8.8.8.8
nameserver 114.114.114.114
EOF
#防火墙和安全功能
iptables -F
systemctl disable firewalld"
systemctl stop firewalld"
sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
#6443端口未被占用
yum install -y lsof
lsof -nP -p 6443 | grep LISTEN

#cp
#mac
#curl -sfL https://get-kk.kubesphere.io | VERSION=v3.0.1 sh -
wget -c https://github.com/kubesphere/kubekey/releases/download/v3.0.1/kubekey-v3.0.1-darwin-amd64.tar.gz
tar xzvf /Volumes/data/downloads/kubekey-v3.0.1-darwin-amd64.tar.gz
kk create config --with-kubesphere v3.3.1
cp config-sample.yaml config-sample.yaml.bk
kk version --show-supported-k8s
#修改config-sample.yaml
:<<EOF
  hosts:
  - {name: dtpct, address: 192.168.3.14, internalAddress: 192.168.3.14, user: root, password: asdf}
  - {name: mdubu, address: 192.168.3.103, internalAddress: 192.168.3.103, user: root, password: asdf}
  - {name: mdlapubu, address: 192.168.3.6, internalAddress: 192.168.3.6, user: root, password: asdf}
  roleGroups:
    etcd:
    - dtpct
    control-plane:
    - dtpct
    worker:
    - mdubu
    - mdlapubu

  kubernetes:
    version: v1.21.14
    clusterName: cluster.local
    autoRenewCerts: true
    containerManager: containerd

  logging:
    enabled: true
    containerruntime: containerd

EOF
export KKZONE=cn
kk create cluster -f config-sample.yaml