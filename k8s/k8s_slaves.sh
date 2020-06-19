#！！！手工, 新机器加入集群跳过所有cat EOF文件生成步骤

#controlplane/master01
#root

file=/root/kubejoin.sh
rm -f $file
cat >> $file << EOF
kubeadm join api.k8s.at.bronzels:6443 --token 42ypg3.xns4cl9xka8nd2r7 \
    --discovery-token-ca-cert-hash sha256:bc4c9d19ab536b41c7c839a51360b469ad76ec5d706b777ac3e14d76e0e67ed7
EOF
ansible slavek8s -m copy -a"src=$file dest=/root"
ansible slavek8s -m shell -a"chmod a+x $file"

ansible slavek8s -m shell -a"/root/kubejoin.sh"

kubectl get node -n kube-system
