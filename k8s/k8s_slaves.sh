#！！！手工, 新机器加入集群跳过所有cat EOF文件生成步骤

#controlplane/master01
#root

file=/root/kubejoin.sh
rm -f $file
cat >> $file << EOF
kubeadm join api.k8s.at.bronzels:6443 --token 42ypg3.xns4cl9xka8nd2r7 \
    --discovery-token-ca-cert-hash sha256:f04891aeef5e5b8ce3eb8fefb97792ea3b9b2b8e79e10104d1647767173ecada
EOF
ansible slave -m copy -a"src=$file dest=/root"
ansible slave -m shell -a"chmod a+x $file"

ansible slave -m shell -a"/root/kubejoin.sh"

kubectl get node -n kube-system
