#！！！手工, 新机器加入集群跳过所有cat EOF文件生成步骤
#root
ansible allk8s -m shell -a"ufw disable"
ansible allk8s -m shell -a"apt install -y selinux-utils"
ansible allk8s -m shell -a"swapoff -a"
ansible allk8s -m shell -a"setenforce 0"

mkdir /etc/sysconfig;echo SELINUX=disabled > /etc/sysconfig/selinux
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

ansible allk8s -m shell -a"curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -"
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF
ansible allk8sexpcp -m copy -a"src=/etc/apt/sources.list.d/kubernetes.list dest=/etc/apt/sources.list.d"
ansible allk8s -m shell -a"apt-get update"
ansible allk8s -m shell -a"apt-get install -y kubelet kubeadm kubectl"

#root
ansible allk8s -m shell -a"kubeadm reset -f"

ansible allk8s -m shell -a"ipvsadm --clear"

ansible allk8s -m shell -a"rm -rf /root/.kube"
ansible allk8s -m shell -a"rm -rf /etc/kubernetes/*"
ansible allk8s -m shell -a"rm -rf /home/ubuntu/.kube"

ansible allk8s -m shell -a"systemctl enable kubelet"

#kubeadm init --kubernetes-version=v1.18.3 --apiserver-advertise-address=10.10.2.81 --pod-network-cidr=10.244.0.0/16

cat << \EOF > kubeadm-config-old.yaml
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
###指定k8s的版本###
kubernetesVersion: v1.18.3

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

cat << \EOF > kubeadm-config.yaml
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
  advertiseAddress: 10.10.3.189
  bindPort: 6443
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  name: hk-prod-bigdata-master-3-189
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
kubernetesVersion: v1.18.3
networking:
  dnsDomain: cluster.local
  podSubnet: 192.168.0.0/16
  serviceSubnet: 10.96.0.0/12
scheduler: {}
EOF

#！！！手工，替换正确的control plan IP地址
sed -i 's@10.10.3.189@10.10.7.44@g' kubeadm-config.yaml
sed -i 's@hk-prod-bigdata-master-3-189@hk-prod-bigdata-master-7-44@g' kubeadm-config.yaml

ansible masterk8sexpcp -m copy -a"src=~/kubeadm-config.yaml dest=~"

:<<EOF
error execution phase preflight: [preflight] Some fatal errors occurred:
	[ERROR FileContent--proc-sys-net-bridge-bridge-nf-call-iptables]: /proc/sys/net/bridge/bridge-nf-call-iptables does not exist
	[ERROR FileContent--proc-sys-net-ipv4-ip_forward]: /proc/sys/net/ipv4/ip_forward contents are not set to 1
EOF
ansible all -m shell -a"modprobe br_netfilter"
ansible all -m shell -a"echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables"

kubeadm init --config kubeadm-config.yaml
#kubeadm token create --print-join-command|sed 's/${LOCAL_IP}/${VIP}/g'

#root
mkdir -p $HOME/.kube
\cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

#ubuntu
mkdir -p $HOME/.kube
sudo \cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#root
#kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
wget -c https://docs.projectcalico.org/v3.9/manifests/calico.yaml
kubectl apply -f calico.yaml
#kubectl delete -f calico.yaml

:<<EOF
kubectl get podpreset
#if return, error: the server doesn't have a resource type "podpreset", then should be enabled first
file=/etc/kubernetes/manifests/kube-apiserver.yaml
cp ${file} ${file}.bk
ansible masterk8s -m shell -a"cp ${file} ${file}.bk"
ansible masterk8s -m shell -a"sed -i '/    - --enable-admission-plugins/a\    - --runtime-config=settings.k8s.io/v1alpha1=true' ${file}"
--runtime-config=settings.k8s.io/v1alpha1=true
ansible masterk8s -m shell -a"cat ${file}"
kubectl get pod -n kube-system
kubectl get podpreset
    volumeMounts:
      - name: mytz-config
        mountPath: /etc/localtime
  volumes:
    - name: mytz-config
      hostPath:
        path: /usr/share/zoneinfo/Asia/Shanghai
EOF

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
    return 1
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
. ${file}
