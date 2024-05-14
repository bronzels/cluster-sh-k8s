if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    MYHOME=/Volumes/data
    BININSTALLED=/Users/apple/bin
    os=darwin
    SED=gsed
else
    echo "Assuming linux by default."
    #linux
    MYHOME=~
    BININSTALLED=~/bin
    os=linux
    SED=sed
fi
SEALOSHOME=$MYHOME/workspace/cluster-sh-k8s/k8s-sealos
cd $SEALOSHOME

#SEALOS_VERSION=4.1.3
SEALOS_VERSION=4.2.0-alpha2
#SEALOS_VERSION=4.1.7

#root
#linux
#ubuntu
#workers
apt install -y iptables ethtool socat ipvsadm
#centos
#workers
yum install -y iptables ethtool socat ipvsadm
#server sealos runs on
#install helm

#cp
#linux
:<<EOF
wget -c https://github.com/labring/sealos/releases/download/v${SEALOS_VERSION}/sealos_${SEALOS_VERSION}_linux_amd64.tar.gz  && \
    tar -zxvf sealos_${SEALOS_VERSION}_linux_amd64.tar.gz sealos &&  chmod +x sealos
mv sealos /usr/bin
EOF
#mv /usr/bin/sealos.4.1.3 /usr/bin/sealos
mv /usr/bin/sealos /usr/bin/sealos.4.1.3
wget -c https://github.com/labring/sealos/releases/download/v${SEALOS_VERSION}/sealos_${SEALOS_VERSION}_linux_amd64.tar.gz
mkdir sealos-${SEALOS_VERSION}
tar -zxvf sealos_${SEALOS_VERSION}_linux_amd64.tar.gz -C sealos-${SEALOS_VERSION}/
mv sealos-${SEALOS_VERSION} /usr/local/sealos
mv /usr/local/sealos.${SEALOS_VERSION} /usr/local/sealos
echo "export PATH=$PATH:/usr/local/sealos" >> ~/.bashrc
. ~/.bashrc

#4.1.7
sealos run labring/kubernetes:v1.21.14-4.1.3 labring/calico:v3.24.1 \
     --masters 192.168.3.14 \
     --cluster-root /data0/sealos \
     --nodes 192.168.3.103,192.168.3.6 \
     -p asdf
#4.2.0-alpha2
#sealos run registry.cn-hangzhou.aliyuncs.com/bronzels/docker.io-labring-kubernetes-v1.25.7:1.0 registry.cn-hangzhou.aliyuncs.com/bronzels/docker.io-labring-calico-v3.24.5:1.0 \
sealos run labring/kubernetes:v1.25.7 labring/calico:v3.24.5 \
     --masters 192.168.3.14 \
     --nodes 192.168.3.103,192.168.3.6 \
     -p asdf
:<<EOF
  kubeadm join apiserver.cluster.local:6443 --token <value withheld> \
	--discovery-token-ca-cert-hash sha256:1bff8db8f6ba61014fa228ee6ff8001215ad21e08a8f2c12b689dfbd153022df \
	--control-plane --certificate-key <value withheld>

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join apiserver.cluster.local:6443 --token <value withheld> \
	--discovery-token-ca-cert-hash sha256:1bff8db8f6ba61014fa228ee6ff8001215ad21e08a8f2c12b689dfbd153022df 
20
W1025 09:27:49.889291   48066 strict.go:54] error unmarshaling configuration schema.GroupVersionKind{Group:"kubeproxy.config.k8s.io", Version:"v1alpha1", Kind:"KubeProxyConfiguration"}: error unmarshaling JSON: while decoding JSON: json: unknown field "detectLocal"
W1025 09:27:49.891311   48066 strict.go:54] error unmarshaling configuration schema.GroupVersionKind{Group:"kubelet.config.k8s.io", Version:"v1beta1", Kind:"KubeletConfiguration"}: error unmarshaling JSON: while decoding JSON: json: unknown field "flushFrequency"
[init] Using Kubernetes version: v1.21.14
[preflight] Running pre-flight checks

W1025 09:27:49.889291   48066 strict.go:54] error unmarshaling configuration schema.GroupVersionKind{Group:"kubeproxy.config.k8s.io", Version:"v1alpha1", Kind:"KubeProxyConfiguration"}: error unmarshaling JSON: while decoding JSON: json: unknown field "detectLocal"
W1025 09:27:49.891311   48066 strict.go:54] error unmarshaling configuration schema.GroupVersionKind{Group:"kubelet.config.k8s.io", Version:"v1beta1", Kind:"KubeletConfiguration"}: error unmarshaling JSON: while decoding JSON: json: unknown field "flushFrequency"
[init] Using Kubernetes version: v1.21.14
[preflight] Running pre-flight checks
EOF

#如果需要主节点参与调度
#kubernetes 1.21
kubectl taint nodes dtpct node-role.kubernetes.io/master:NoSchedule-
#kubernetes 1.25
kubectl taint nodes dtpct node-role.kubernetes.io/control-plane:NoSchedule-
kubectl describe node dtpct | grep Taint

#server sealos runs on
#4.1.7
sealos reset \
     --masters 192.168.3.14 \
     --cluster-root /data0/sealos \
     --nodes 192.168.3.103,192.168.3.6 \
     -p asdf
#4.2.0-alpha2
sealos reset \
     --masters 192.168.3.14 \
     --nodes 192.168.3.103,192.168.3.6 \
     -p asdf
ansible all -m shell -a"rm -rf /var/lib/cni;rm -rf /etc/cni;rm -rf /var/lib/etcd;rm -rf /root/.kube;rm -rf /etc/kubernetes/"
ansible all -m shell -a"ipvsadm --clear"

#如果需要删除下载或者恢复的镜像
sealos rmi -f
ansible all -m shell -a"rm -rf /data0/containerd"

sealos save -o kubernetes-1.21.14.tar labring/kubernetes:v1.21.14-4.1.3
sealos save -o calico-3.24.1.tar labring/calico:v3.24.1

sealos load -i /data0/kubernetes-1.21.14.tar
sealos load -i /data0/calico-3.24.1.tar

scp root@dtpct:/etc/containerd/config.toml ./config.toml.bk
#修改mirror和harbor部分
ansible all -m shell -a"systemctl stop containerd.service"
#删除了数据盘镜像
ansible all -m shell -a"mv /var/lib/containerd /data0/"
#保留了数据盘镜像
ansible all -m shell -a"rm -rf /var/lib/containerd"
ansible all -m shell -a"cd /etc/containerd;mv config.toml config.toml.bk"
ansible all -m copy -a"src=./config.toml dest=/etc/containerd/config.toml"
ansible all -m shell -a"cat /etc/containerd/config.toml|grep my.org"
ansible all -m shell -a"cat /etc/containerd/config.toml|grep BinaryName"
ansible all -m shell -a"systemctl start containerd.service"
ansible all -m shell -a"systemctl status containerd.service"

ansible all -m shell -a"ctr -n k8s.io container list"
ansible all -m shell -a"ctr -n k8s.io c ls"
ansible all -m shell -a"crictl ps -a|grep Exited"

#集群某一台，如果镜像起作用2分钟左右应该能拉下来
start=$(date +"%s.%9N")
crictl pull python:2.7
end=$(date +"%s.%9N")
echo timediff:`echo "scale=9;$end - $start" | bc`
crictl images


ansible all -m shell -a"ctr -n k8s.io c ls | awk '{print $1}' | xargs ctr -n k8s.io c stop $1 && ctr -n k8s.io c remove $1"
ansible all -m shell -a"crictl ps -a| awk '{print $1}' | xargs crictl stop $1 && crictl remove $1"
