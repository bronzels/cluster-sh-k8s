#！！！手工, 新机器加入集群跳过所有cat EOF文件生成步骤

#root
#controlplane/master01

file=/root/kubecacp-cert-masters.sh
rm -f $file
cat << \EOF > ${file}
#!/bin/bash

vhost="master02"
usr=root

who=`whoami`
if [ "$who" != "$usr" ]; then
  echo "请使用 root 用户执行或者 sudo ./sync.master.ca.sh"
  exit 1
fi

echo $who

# 需要从 node1 拷贝的 ca 文件
caFiles=(
/etc/kubernetes/pki/ca.crt
/etc/kubernetes/pki/ca.key
/etc/kubernetes/pki/sa.key
/etc/kubernetes/pki/sa.pub
/etc/kubernetes/pki/front-proxy-ca.crt
/etc/kubernetes/pki/front-proxy-ca.key
/etc/kubernetes/pki/etcd/ca.crt
/etc/kubernetes/pki/etcd/ca.key
/etc/kubernetes/admin.conf
)

pkiDir=/etc/kubernetes/pki/etcd
for h in $vhost
do
  ssh ${usr}@$h "mkdir -p $pkiDir"
  echo "Dirs for ca scp created, start to scp..."

  # scp 文件到目标机
  for var in "${caFiles[@]}";
  do
    #echo "var:$var"
    path=${var%/*}
    #echo "path:$path"
    file=${var##*/}
    #echo "file:$file"
  	scp $var ${usr}@$h:$path
  done

  echo "Ca files transfered for $h ... ok"
done
EOF
chmod a+x /root/kubecacp-cert-masters.sh
/root/kubecacp-cert-masters.sh

file=/root/kubejoin-master.sh
rm -f $file
cat >> $file << EOF
  kubeadm join api.k8s.at.bronzels:6443 --token 42ypg3.xns4cl9xka8nd2r7 \
    --discovery-token-ca-cert-hash sha256:301db453a8d682dbf090388ce03f0b4273a78363e0ee25cb2564656aa1a65ef1 \
    --control-plane
EOF
ansible masterexpcp -m copy -a"src=$file dest=/root"
ansible masterexpcp -m shell -a"chmod a+x $file"

ansible masterexpcp -m shell -a"/root/kubejoin-master.sh"

kubectl get node -n kube-system

