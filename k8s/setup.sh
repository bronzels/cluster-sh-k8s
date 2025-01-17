#！！！手工, 新机器加入集群跳过所有cat EOF文件生成步骤
#root
#ubuntu
ansible allk8s -m shell -a"ufw disable"
#centos
ansible allk8s -m shell -a"systemctl stop firewalld"
ansible allk8s -m shell -a"systemctl disable firewalld"

#ubuntu
ansible allk8s -m shell -a"apt install -y selinux-utils"
ansible allk8s -m shell -a"setenforce 0"
#centos
systemctl stop firewalld.service 
systemctl disable firewalld.service
sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config

ansible allk8s -m shell -a"swapoff -a"
#vi /etc/fstab   #永久关闭，删除或者注释掉swap配置哪一行
#把数据盘加入
#/dev/disk/by-uuid/4d3c832b-e040-4243-8a47-c96d38cb2027 /data0 xfs defaults 0 1

#ubuntu
#禁止ipv6
file=/etc/sysctl.conf
cp $file $file.bk
cat >> $file << EOF
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
EOF
sudo sysctl -p
ansible allk8sexpcp -m shell -a"mkdir /etc/sysconfig"
ansible allk8sexpcp -m copy -a"src=/etc/sysconfig/selinux dest=/etc/sysconfig"
ansible allk8s -m shell -a"ls /etc/sysconfig/modules/"
ansible allk8s -m shell -a"rm -rf /etc/sysconfig/modules/;mkdir -p /etc/sysconfig/modules/"

file=/etc/sysctl.d/k8s-sysctl.conf
rm -f $file
cat >> $file << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_nonlocal_bind = 1
net.ipv4.ip_forward = 1
vm.swappiness=0
EOF
ansible allk8sexpcp -m copy -a"src=/etc/sysctl.d/k8s-sysctl.conf dest=/etc/sysctl.d"
ansible allk8s -m shell -a"sysctl -p /etc/sysctl.d/k8s-sysctl.conf"

#ubuntu
ansible allk8s -m shell -a"curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -"
#ubuntu 16/18
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF
ansible allk8sexpcp -m copy -a"src=/etc/apt/sources.list.d/kubernetes.list dest=/etc/apt/sources.list.d"
ansible allk8s -m shell -a"apt-get update"
rev=1.21.8-00
apt-get install -y kubelet=$rev kubeadm=$rev kubectl=$rev
ansible allk8s -m shell -a"apt-get install -y kubelet=$rev kubeadm=$rev kubectl=$rev"
#centos
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
        https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
EOF
rev=1.21.8
yum install -y kubelet-$rev kubeadm-$rev kubectl-$rev
docker ps -a | grep k8s
docker ps -a|grep Exited

ansible allk8s -m shell -a"systemctl start kubelet"
ansible allk8s -m shell -a"systemctl enable kubelet"
systemctl start kubelet
systemctl enable kubelet
docker ps -a | grep k8s
docker ps -a|grep Exited

#kubeadm init --kubernetes-version=v1.18.3 --apiserver-advertise-address=1110.1110.2.81 --pod-network-cidr=10.244.0.0/16

cat << EOF > kubeadm-config-old.yaml
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
###指定k8s的版本###
kubernetesVersion: v1.18.5

### apiServerCertSANs 填所有的masterip,lbip其它可能需要通过它访问apiserver的地址,域名或主机名等 ###
### 如阿里fip,证书中会允许这些ip ###
### 这里填一个自定义的域名 ###
### 用于访问APIServer的LB,一般通过nginx或者haproxy做集群解析.可以在每台服务器做hosts映射到127.0.0.1 然后每台服务器上都安装nginx,做upstream,用于健康检查.  ###
### 这里我为了方便,修改三台服务器上的 /etc/hosts ,把有三个master的IP都解析到 domain 的域名,hosts好像做了健康检查,代替了DNS的功能 ###
apiServer:
  ###添加域名的SSL证书###
  certSANs:
  - "api.k8s.at.bronzels"
###apiServer的集群访问地址###
controlPlaneEndpoint: "api.k8s.at.bronzels:6443"

### calico 网络插件的子网 ###
networking:
  podSubnet: "192.168.0.0/16"
EOF
#kubeadm config migrate --old-config kubeadm-config-old.yaml --new-config kubeadm-config.yaml

#！！！手工, 如果要升级k8s版本，替换kubernetesVersion: v1.18.5
cat << EOF > kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta2
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: 42ypg3.xns4cl9xka8nd2r7
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 1110.1110.9.83
  bindPort: 6443
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  name: hk-prod-bigdata-master-9-83
  taints:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
---
apiServer:
  certSANs:
  - api.k8s.at.bronzels
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta2
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controlPlaneEndpoint: api.k8s.at.bronzels:6443
controllerManager: {}
dns:
  type: CoreDNS
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: k8s.gcr.io
kind: ClusterConfiguration
kubernetesVersion: v1.21.8
networking:
  dnsDomain: cluster.local
  podSubnet: 192.168.0.0/16
  serviceSubnet: 10.96.0.0/12
EOF

kubeadm init \ --apiserver-advertise-address=172.16.10.11 \ --image-repository registry.aliyuncs.com/google_containers \ --kubernetes-version v1.22.4 \ --service-cidr=10.96.0.0/12 \ --pod-network-cidr=10.244.0.0/16 \ --ignore-preflight-errors=all --apiserver-advertise-address

#！！！手工，替换正确的control plan IP地址
sed -i 's@1110.1110.3.189@1110.1110.9.83@g' kubeadm-config.yaml
sed -i 's@hk-prod-bigdata-master-3-189@hk-prod-bigdata-master-9-83@g' kubeadm-config.yaml

ansible masterk8sexpcp -m copy -a"src=~/kubeadm-config.yaml dest=~"

kubeadm init --config kubeadm-config.yaml
#kubeadm token create --print-join-command|sed 's/${LOCAL_IP}/${VIP}/g'
docker ps -a | grep k8s
docker ps -a|grep Exited

:<<EOF
error execution phase preflight: [preflight] Some fatal errors occurred:
	[ERROR FileContent--proc-sys-net-bridge-bridge-nf-call-iptables]: /proc/sys/net/bridge/bridge-nf-call-iptables does not exist
	[ERROR FileContent--proc-sys-net-ipv4-ip_forward]: /proc/sys/net/ipv4/ip_forward contents are not set to 1
EOF

echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bashrc
. ~/.bashrc

#如果出现以上错误，执行以下步骤
ansible all -m shell -a"modprobe br_netfilter"
ansible all -m shell -a"echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables"

#root
rm -rf $HOME/.kube
mkdir -p $HOME/.kube
cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

#如果需要主节点参与调度
kubectl taint nodes dtpct node-role.kubernetes.io/master:NoSchedule-
kubectl describe node dtpct | grep Taint

kubectl get node
kubectl get pod -n kube-system

#ubuntu
mkdir -p $HOME/.kube
sudo \cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#1.22版本的k8s，和calico以下方式获得的calico兼容总有问题，或者calico-node报BGP错误，或者从节点加入以后controller报无法获取集群信息的错误。
#只有工程自带这个calico.yaml没问题
sudo su -
#root
#kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
wget -c https://docs.projectcalico.org/v3.9/manifests/calico.yaml
#wget https://docs.projectcalico.org/manifests/calico.yaml
cp calico.yaml calico.yaml.bk
cat calico.yaml  |grep image
sed -i 's#docker.io/##g' calico.yaml
cat calico.yaml  |grep image
#calico问题一般是iptable导致，清空就好了，还有问题可以尝试
:<<\EOF
调整calicao 网络插件的网卡发现机制，修改IP_AUTODETECTION_METHOD对应的value值。官方提供的yaml文件中，ip识别策略（IPDETECTMETHOD）没有配置，即默认为first-found，这会导致一个网络异常的ip作为nodeIP被注册，从而影响node-to-node mesh。我们可以修改成can-reach或者interface的策略，尝试连接某一个Ready的node的IP，以此选择出正确的IP。
// calico.yaml 文件添加以下二行
            - name: IP_AUTODETECTION_METHOD
              value: "interface=enp.*"  # ens 根据实际网卡开头配置
// 配置如下
            - name: CLUSTER_TYPE
              value: "k8s,bgp"
            - name: IP_AUTODETECTION_METHOD
              value: "interface=eth.*"
              #或者 value: "interface=eth0" # 我选用的这个
            # Auto-detect the BGP IP address.
            - name: IP
              value: "autodetect"
            # 关闭IPIP模式
            - name: CALICO_IPV4POOL_IPIP
              #value: "Always"
              value: "off"
// 如果kubeadm初始化定义的pod网段不同需要修改
            # - name: CALICO_IPV4POOL_CIDR
            #   value: "192.168.0.0/16"
EOF
kubectl apply -f calico.yaml
#kubectl delete -f calico.yaml
docker ps -a | grep k8s
docker ps -a|grep Exited

kubectl get pod -n kube-system

#ubuntu
file=~/scripts/k8s_funcs.sh
cat << \EOF > ${file}
#!/bin/bash

nofound="No resources found"

function if_namespace_exists(){
  k8sfunc_ns=$1
  echo "k8sfunc_ns:${k8sfunc_ns}"

  greppedrst=`kubectl get namespaces | grep ${k8sfunc_ns}`
  if [[ -z "${greppedrst}" ]]; then
    return 0
  else
    return 1
  fi
}

function wait_pod_deleted(){
  echo "in wait_pod_deleted"

  k8sfunc_ns=$1
  echo "k8sfunc_ns:${k8sfunc_ns}"
  if_namespace_exists "${k8sfunc_ns}"
  funcrst=`echo $?`
  echo "line:$LINENO, funcrst:${funcrst}"
  if [ ${funcrst} -eq 0 ]; then
    echo "no such k8sfunc_ns:${k8sfunc_ns}"
    return 1
  fi
  k8sfunc_name2grep=$2
  echo "k8sfunc_name2grep:${k8sfunc_name2grep}"
  timeoutsec=$3
  echo "timeoutsec:${timeoutsec}"

  time_start=`date +"%s"`
  time_total=0
  while [ 1 ]
  do
    result=`kubectl get pod -n ${k8sfunc_ns} | grep ${k8sfunc_name2grep}`
    if [[ -z ${result} ]] ;then
      echo "success, no pods named ${k8sfunc_name2grep} anymore"
      return 0
    else
      echo "result:"
      echo "${result}"
      sleep 5
    fi
    time_check=`date +"%s"`
    let time_total=time_check-time_start
    echo "time_total:${time_total}"
    if [ ${time_total} -gt ${timeoutsec} ] ;then
       echo "failed to wait untill all pod deleted, timeout"
       return 1
    fi
  done
  return 0
}

function wait_pod_running(){
  echo "in wait_pod_running"

  k8sfunc_ns=$1
  echo "k8sfunc_ns:${k8sfunc_ns}"
  if_namespace_exists "${k8sfunc_ns}"
  funcrst=`echo $?`
  echo "line:$LINENO, funcrst:${funcrst}"
  if [ ${funcrst} -eq 0 ]; then
    echo "no such k8sfunc_ns:${k8sfunc_ns}"
    return 1
  fi
  k8sfunc_name2grep=$2
  echo "k8sfunc_name2grep:${k8sfunc_name2grep}"
  k8sfunc_replicas=$3
  echo "k8sfunc_replicas:${k8sfunc_replicas}"
  timeoutsec=$4
  echo "timeoutsec:${timeoutsec}"

  time_start=`date +"%s"`
  time_total=0
  while [ 1 ]
  do
    OLDIFS="$IFS"
    IFS=$'\n'
    file_paths=($(find ~/ -name '*.mkv'))
    result_arr=($(kubectl get pod -n ${k8sfunc_ns} | grep ${k8sfunc_name2grep}))
    IFS="$OLDIFS"
    running_total=0
    for result in "${result_arr[@]}";
    do
      echo "result:${result}"
      if [[ -z ${result} ]] ;then
        continue
      fi
      podname=`echo ${result} | awk '{print $1}'`
      echo "podname:${podname}"
      ready=`echo ${result} | awk '{print $2}'`
      echo "ready:${ready}"
      status=`echo ${result} | awk '{print $3}'`
      echo "status:${status}"
      if [ ${ready} == "1/1" -a ${status} == "Running" ]; then
         let running_total=running_total+1
      fi
    done
    if [ ${running_total} -eq ${k8sfunc_replicas} ] ;then
      echo "success, all ${k8sfunc_replicas} pods named ${k8sfunc_name2grep} running 1/1"
      return 0
    else
      echo "k8sfunc_replicas:${k8sfunc_replicas}, running_total:${running_total}"
    fi
    sleep 5
    time_check=`date +"%s"`
    let time_total=time_check-time_start
    echo "time_total:${time_total}"
    if [ ${time_total} -gt ${timeoutsec} ] ;then
       echo "failed to wait untill all pod deleted, timeout"
       return 1
    fi
  done
  return 0
}

function if_resource_with_exactname_exists(){
  k8sfunc_ns=$1
  echo "k8sfunc_ns:${k8sfunc_ns}"
  if_namespace_exists "${k8sfunc_ns}"
  funcrst=`echo $?`
  echo "line:$LINENO, funcrst:${funcrst}"
  if [ ${funcrst} -eq 0 ]; then
    echo "no such k8sfunc_ns:${k8sfunc_ns}"
    return 0
  fi
  res=$2
  echo "res:${res}"
  resname=$3
  echo "resname:${resname}"

  greppedrst=`kubectl get ${res} -n ${k8sfunc_ns} | grep ${resname}`
  echo "greppedrst:${greppedrst}"
  if [[ -z "${greppedrst}" ]]; then
    return 0
  else
    return 1
  fi
  return 0
}

function wait_pod_specific_log_line(){
  echo "in wait_pod_specific_log_line"

  k8sfunc_ns=$1
  echo "k8sfunc_ns:${k8sfunc_ns}"
  if_namespace_exists "${k8sfunc_ns}"
  funcrst=`echo $?`
  echo "line:$LINENO, funcrst:${funcrst}"
  if [ ${funcrst} -eq 0 ]; then
    echo "no such k8sfunc_ns:${k8sfunc_ns}"
    return 1
  fi
  k8sfunc_name2grep=$2
  echo "k8sfunc_name2grep:${k8sfunc_name2grep}"
  k8sfunc_logpath=$3
  echo "k8sfunc_logpath:${k8sfunc_logpath}"
  k8sfunc_logline=$4
  echo "k8sfunc_logline:${k8sfunc_logline}"
  timeoutsec=$5
  echo "timeoutsec:${timeoutsec}"

  time_start=`date +"%s"`
  time_total=0
  while [ 1 ]
  do
    result=`kubectl get pod -n ${k8sfunc_ns} | awk '{print $1}' | grep ${k8sfunc_name2grep} | xargs -I CNAME  sh -c "kubectl exec -n ${k8sfunc_ns} CNAME -- cat ${k8sfunc_logpath}|grep '${k8sfunc_logline}'"`
    if [[ -z ${result} ]] ;then
      sleep 5
    else
      echo "success, specific log line:${k8sfunc_logline} detected in ${k8sfunc_name2grep} pod as result:"
      echo "${result}"
      return 0
    fi
    time_check=`date +"%s"`
    let time_total=time_check-time_start
    echo "time_total:${time_total}"
    if [ ${time_total} -gt ${timeoutsec} ] ;then
       echo "failed to detect specific log line, timeout"
       return 1
    fi
  done
  return 0
}

function wait_pod_log_line(){
  echo "in wait_pod_log_line"

  k8sfunc_ns=$1
  echo "k8sfunc_ns:${k8sfunc_ns}"
  if_namespace_exists "${k8sfunc_ns}"
  funcrst=`echo $?`
  echo "line:$LINENO, funcrst:${funcrst}"
  if [ ${funcrst} -eq 0 ]; then
    echo "no such k8sfunc_ns:${k8sfunc_ns}"
    return 1
  fi
  k8sfunc_name2grep=$2
  echo "k8sfunc_name2grep:${k8sfunc_name2grep}"
  k8sfunc_logline=$3
  echo "k8sfunc_logline:${k8sfunc_logline}"
  timeoutsec=$4
  echo "timeoutsec:${timeoutsec}"

  time_start=`date +"%s"`
  time_total=0
  while [ 1 ]
  do
    result=`kubectl get pod -n ${k8sfunc_ns} | awk '{print $1}' | grep ${k8sfunc_name2grep} | xargs -I CNAME  sh -c "kubectl logs -n ${k8sfunc_ns} CNAME | grep '${k8sfunc_logline}'"`
    if [[ -z ${result} ]] ;then
      sleep 5
    else
      echo "success, specific log line:${k8sfunc_logline} detected in ${k8sfunc_name2grep} pod as result:"
      echo "${result}"
      return 0
    fi
    time_check=`date +"%s"`
    let time_total=time_check-time_start
    echo "time_total:${time_total}"
    if [ ${time_total} -gt ${timeoutsec} ] ;then
       echo "failed to detect specific log line, timeout"
       return 1
    fi
  done
  return 0
}

function fix_statfulset_rev_beta1(){
  k8sfunc_file=$1
  sed -i 's@apps\/v1beta1@apps\/v1@g' ${k8sfunc_file}
}

function fix_statfulset_rev_beta2(){
  k8sfunc_file=$1
  sed -i 's@apps\/v1beta2@apps\/v1@g' ${k8sfunc_file}
}

function delete_pvc_by_ns2name(){
  k8sfunc_ns=$1
  echo "k8sfunc_ns:${k8sfunc_ns}"
  k8sfunc_name2grep=$2
  echo "k8sfunc_name2grep:${k8sfunc_name2grep}"
  kubectl get pvc -n ${k8sfunc_ns} | grep ${k8sfunc_name2grep} | awk '{print $1}' | xargs kubectl -n ${k8sfunc_ns} delete pvc
}

function uinstall_helm_if_found(){
  k8sfunc_ns=$1
  echo "k8sfunc_ns:${k8sfunc_ns}"
  k8sfunc_name=$2
  echo "k8sfunc_name:${k8sfunc_name}"

  found=`helm list -n ${k8sfunc_ns} | grep ${k8sfunc_name}`
  if [[ -n ${found} ]]; then
    echo "found"
    helm uninstall ${k8sfunc_name} -n ${k8sfunc_ns}
  else
    echo "not found"
  fi
}

EOF
chmod a+x ${file}

file=~/sources.list.debian8
cat << \EOF > ${file}
deb http://mirrors.163.com/debian/ jessie main non-free contrib
deb http://mirrors.163.com/debian/ jessie-updates main non-free contrib
deb http://mirrors.163.com/debian/ jessie-backports main non-free contrib
deb-src http://mirrors.163.com/debian/ jessie main non-free contrib
deb-src http://mirrors.163.com/debian/ jessie-updates main non-free contrib
deb-src http://mirrors.163.com/debian/ jessie-backports main non-free contrib
deb http://mirrors.163.com/debian-security/ jessie/updates main non-free contrib
deb-src http://mirrors.163.com/debian-security/ jessie/updates main non-free contrib
EOF

file=~/sources.list.ubuntu.16.04
cat << \EOF > ${file}
deb-src http://archive.ubuntu.com/ubuntu xenial main restricted #Added by software-properties
deb http://mirrors.aliyun.com/ubuntu/ xenial main restricted
deb-src http://mirrors.aliyun.com/ubuntu/ xenial main restricted multiverse universe #Added by software-properties
deb http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted multiverse universe #Added by software-properties
deb http://mirrors.aliyun.com/ubuntu/ xenial universe
deb http://mirrors.aliyun.com/ubuntu/ xenial-updates universe
deb http://mirrors.aliyun.com/ubuntu/ xenial multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-updates multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse #Added by software-properties
deb http://archive.canonical.com/ubuntu xenial partner
deb-src http://archive.canonical.com/ubuntu xenial partner
deb http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted multiverse universe #Added by software-properties
deb http://mirrors.aliyun.com/ubuntu/ xenial-security universe
deb http://mirrors.aliyun.com/ubuntu/ xenial-security multiverse
EOF
