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
wget -c https://github.com/labring/sealos/releases/download/v4.1.3/sealos_4.1.3_linux_amd64.tar.gz  && \
    tar -zxvf sealos_4.1.3_linux_amd64.tar.gz sealos &&  chmod +x sealos
mv sealos /usr/bin

sealos run labring/kubernetes:v1.21.14-4.1.3 labring/calico:v3.24.1 \
     --masters 192.168.3.14 \
     --cluster-root /data0/sealos \
     --nodes 192.168.3.103,192.168.3.6 \
     -p asdf
:<<EOF
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
kubectl taint nodes dtpct node-role.kubernetes.io/master:NoSchedule-
kubectl describe node dtpct | grep Taint

#server sealos runs on
sealos reset \
     --masters 192.168.3.14 \
     --cluster-root /data0/sealos \
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
ansible all -m shell -a"mv /var/lib/containerd /data0/"
ansible all -m shell -a"cd /etc/containerd;mv config.toml config.toml.bk"
ansible all -m copy -a"src=./config.toml dest=/etc/containerd/config.toml"
ansible all -m shell -a"cat /etc/containerd/config.toml|grep my.org"
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
