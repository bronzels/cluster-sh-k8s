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

ansible all -m shell -a"cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF"

modprobe overlay && modprobe br_netfilter

ansible all -m shell -a""
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
yum makecache 
#rev=1.26.3
#rev=1.25.9
#rev=1.22.17
#rev=1.18.12
rev=1.21.14
yum install -y kubelet-$rev kubeadm-$rev kubectl-$rev
systemctl start kubelet
systemctl status kubelet
systemctl enable kubelet

sed -i 's@--network-plugin=cni @@g' /var/lib/kubelet/kubeadm-flags.env
systemctl restart kubelet
#用docker做container时，安装了calico继续dns的pod pending，master提示NotReady，kubelet的状态container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:docker:
#改成--network-plugin-dir=/opt/cni/bin --network-plugin=cni --cni-conf-dir=/etc/cni/net.d/也不行

kubeadm config print init-defaults --component-configs KubeletConfiguration > kubeadm.yaml.1.18

:<<EOF
advertiseAddress: 1.2.3.4
=>
advertiseAddress: 192.168.30.88

criSocket: unix:///var/run/containerd/containerd.sock
=>
criSocket: /run/containerd/containerd.sock
criSocket: /var/run/dockershim.sock

name: node
=>
name: kubernetes-master

imageRepository: registry.k8s.io
=>
imageRepository: registry.aliyuncs.com/google_containers

kubernetesVersion: 1.26.0
=>
kubernetesVersion: 1.21.14

networking:
  podSubnet: 10.244.0.0/16


---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: ipvs

EOF

#containerd
:<<EOF
sandbox_image = "sealos.hub:5000/pause:3.4.1"
=>
sandbox_image = "registry.aliyuncs.com/google_containers/pause:3.9"
EOF

#cp
containerd_rev=1.6.20
curl -OL https://github.com/containerd/containerd/releases/download/v${containerd_rev}/containerd-${containerd_rev}-linux-amd64.tar.gz
cd /usr/bin;mv containerd-shim containerd-shim.1.6.10;mv containerd-stress containerd-stress.1.6.10;mv containerd containerd.1.6.10;mv ctr ctr.1.6.10;mv containerd-shim-runc-v2 containerd-shim-runc-v2.1.6.10
ls /usr/bin/containerd*
ls /usr/bin/ctr*
tar -zxvf containerd-${containerd_rev}-linux-amd64.tar.gz -C /usr

rm -f /var/run/image-cri-shim.sock

cni_rev=1.2.0
wget -c https://github.com/containernetworking/plugins/releases/download/v${cni_rev}/cni-plugins-linux-amd64-v${cni_rev}.tgz
mkdir -p /opt/cni/bin
tar xvf cni-plugins-linux-amd64-v${cni_rev}.tgz -C /opt/cni/bin/


runc_rev=1.1.5
curl -OL https://github.com/opencontainers/runc/releases/download/v${runc_rev}/runc.amd64
mv runc.amd64 /usr/bin/runc && chmod +x /usr/bin/runc

sudo scp kubeadm.yaml dtpct:/root/
sudo ssh dtpct
	kubeadm init --config=kubeadm.yaml 

kubeadm join 192.168.3.14:6443 --token abcdef.0123456789abcdef \
	--discovery-token-ca-cert-hash sha256:5ddc836708955f1643d28a0a0df38196e904f649d6b19a407eec57c74050f444 

kubectl taint nodes dtpct node-role.kubernetes.io/control-plane:NoSchedule-
kubectl describe node dtpct | grep Taint

kubectl taint nodes --all node-role.kubernetes.io/control-plane-
kubectl taint nodes --all node-role.kubernetes.io/master-

kubectl edit configmap -n kube-system coredns
#在prometheus后面增加
:<<EOF
        hosts {
           192.168.3.14 dtpct
           192.168.3.6 mdlapubu
           192.168.3.103 mdubu
           192.168.3.9 mmubu
           192.168.3.9 harbor.my.org
           192.168.3.9 pypi.my.org
           fallthrough
        }
EOF
kubectl get configmap -n kube-system coredns -o yaml
kubectl get pod -n kube-system |grep coredns |awk '{print $1}'| xargs kubectl delete pod "$1" -n kube-system --force --grace-period=0

calico_short_rev=3.23
calico_rev=3.23.5
:<<EOF
calico_short_rev=3.18
calico_rev=3.18.5

calico_short_rev=3.25
calico_rev=3.25.1

calico_short_rev=3.24
calico_rev=3.24.5
EOF

:<<EOF
wget https://docs.projectcalico.org/v${calico_short_rev}/manifests/calico.yaml -O calico.yaml.${calico_rev}
cp calico.yaml.${calico_rev} calico.yaml
cat calico.yaml  |grep image
$SED -i 's#docker.io/##g' calico.yaml
cat calico.yaml  |grep image
#k8s 1.25.9, calico 3.25.0
cat calico.yaml  |grep "policy/v1"
$SED -i "s@policy/v1beta1@policy/v1@g" calico.yaml
cat calico.yaml  |grep "policy/v1"

kubectl apply -f calico.yaml

kubectl delete -f calico.yaml
EOF

cd /data0

#wget -c https://raw.githubusercontent.com/projectcalico/calico/v${calico_rev}/manifests/tigera-operator.yaml
#wget -c https://raw.githubusercontent.com/projectcalico/calico/v${calico_rev}/manifests/custom-resources.yaml
wget -c https://projectcalico.docs.tigera.io/archive/v${calico_short_rev}/manifests/tigera-operator.yaml -O tigera-operator.yaml.${calico_rev}
#quay.io/tigera/operator:v1.27.16
wget -c https://projectcalico.docs.tigera.io/archive/v${calico_short_rev}/manifests/custom-resources.yaml -O custom-resources.yaml.${calico_rev}
#
cp tigera-operator.yaml.${calico_rev} tigera-operator.yaml
#根据podSubnet: 10.244.0.0/16，修改cidr
cp custom-resources.yaml.${calico_rev} custom-resources.yaml

kubectl create -f tigera-operator.yaml
kubectl create -f custom-resources.yaml

kubectl delete -f custom-resources.yaml
kubectl delete -f tigera-operator.yaml
rm -rf /etc/cni/net.d/*calico*
rm -rf /var/lib/cni/*


ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/docker.io-calico-kube-controllers-v${calico_rev}:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/docker.io-calico-kube-controllers-v${calico_rev}:1.0 docker.io/calico/kube-controllers:v${calico_rev}"
sudo ssh dtpct ctr -n k8s.io i export docker.io-calico-kube-controllers-v${calico_rev}.tar docker.io/calico/kube-controllers:v${calico_rev}

ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/docker.io-calico-cni-v${calico_rev}:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/docker.io-calico-cni-v${calico_rev}:1.0 docker.io/calico/cni:v${calico_rev}"
sudo ssh dtpct ctr -n k8s.io i export docker.io-calico-cni-v${calico_rev}.tar docker.io/calico/cni:v${calico_rev}

ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/docker.io-calico-typha-v${calico_rev}:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/docker.io-calico-typha-v${calico_rev}:1.0 docker.io/calico/typha:v${calico_rev}"
sudo ssh dtpct ctr -n k8s.io i export docker.io-calico-typha-v${calico_rev}.tar docker.io/calico/typha:v${calico_rev}

ansible all -m shell -a"crictl pull registry.cn-hangzhou.aliyuncs.com/bronzels/docker.io-calico-node-driver-registrar-v${calico_rev}:1.0"
ansible all -m shell -a"ctr -n k8s.io i tag registry.cn-hangzhou.aliyuncs.com/bronzels/docker.io-calico-node-driver-registrar-v${calico_rev}:1.0 docker.io/calico/node-driver-registrar:v${calico_rev}"
sudo ssh dtpct ctr -n k8s.io i export docker.io-calico-node-driver-registrar-v${calico_rev}.tar docker.io/calico/node-driver-registrar:v${calico_rev}

imgarr=(docker.io/calico/kube-controllers:v${calico_rev} docker.io/calico/cni:v${calico_rev} docker.io/calico/typha:v${calico_rev} docker.io/calico/node-driver-registrar:v${calico_rev} docker.io/calico/apiserver:v${calico_rev} docker.io/calico/node:v${calico_rev} docker.io/calico/csi:v${calico_rev}）
filearr=(docker.io-calico-kube-controllers-v${calico_rev} docker.io-calico-cni-v${calico_rev} docker.io-calico-typha-v${calico_rev} docker.io-calico-node-driver-registrar-v${calico_rev} docker.io-calico-apiserver-v${calico_rev}.tar docker.io-calico-node-v${calico_rev}.tar docker.io-calico-csi-v${calico_rev}.tar)
for i in ${!imgarr[@]}
do
	img=${imgarr[$i]}
	file=${filearr[$i]}
	docker pull $img
	docker save -o ${file}.tar ${img}
done

filearr=(docker.io-calico-kube-controllers-v${calico_rev} docker.io-calico-cni-v${calico_rev} docker.io-calico-typha-v${calico_rev} docker.io-calico-node-driver-registrar-v${calico_rev} docker.io-calico-apiserver-v${calico_rev}.tar docker.io-calico-node-v${calico_rev}.tar docker.io-calico-csi-v${calico_rev}.tar)
for i in ${!filearr[@]}
do
	file=${filearr[$i]}
	ansible all -m copy -a"src=imgbk-calico-${calico_rev}/${file}.tar dest=/root/"
	ansible all -m shell -a"ctr -n k8s.io i import /root/${file}.tar"
	ansible all -m shell -a"rm -f /root/${file}.tar"
done

kubectl get pods -A |grep -v 'Running' |awk '{printf("kubectl delete pods %s -n %s --force --grace-period=0\n", $2,$1)}' | /bin/bash

kubectl get pods -A |grep -v 'Running\|ContainerCreating\|Pending\|Init' |awk '{printf("kubectl delete pods %s -n %s --force --grace-period=0\n", $2,$1)}' | /bin/bash
ansible all -m shell -a"rm -f /etc/cni/net.d/*"

ctr -n k8s.io image export calico-cni-v${calico_rev}.tar docker.io/calico/cni:v${calico_rev}
ctr -n k8s.io image export calico-node-v${calico_rev}.tar docker.io/calico/node:v${calico_rev}
ctr -n k8s.io image export calico-kube-controllers-v${calico_rev}.tar docker.io/calico/kube-controllers:v${calico_rev}

ctr -n k8s.io image import calico-cni-v${calico_rev}.tar
ctr -n k8s.io image import calico-node-v${calico_rev}.tar
ctr -n k8s.io image import calico-kube-controllers-v${calico_rev}.tar

#k8s 1.25.9, calico 3.25.0
2023-04-18 03:19:20.765 [ERROR][1] client.go 261: Error getting cluster information config ClusterInformation="default" error=Get "https://10.96.0.1:443/apis/crd.projectcalico.org/v1/clusterinformations/default": context deadline exceeded
2023-04-18 03:19:20.765 [FATAL][1] main.go 120: Failed to initialize Calico datastore error=Get "https://10.96.0.1:443/apis/crd.projectcalico.org/v1/clusterinformations/default": context deadline exceeded
#k8s 1.25.9, calico 3.24.5/3.23.5
Warning  FailedCreatePodSandBox  51s                kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to setup network for sandbox "23a2df550a8b02872b72720d116d91e1a24f403e7bb0367094a8a848a55acc03": plugin type="calico" failed (add): error getting ClusterInformation: connection is unauthorized: Unauthorized

