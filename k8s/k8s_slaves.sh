#！！！手工, 新机器加入集群跳过所有cat EOF文件生成步骤

#controlplane/master01
#root

file=/root/kubejoin.sh
rm -f $file
cat >> $file << EOF
kubeadm join api.k8s.at.bronzels:6443 --token 42ypg3.xns4cl9xka8nd2r7 \
    --discovery-token-ca-cert-hash sha256:301db453a8d682dbf090388ce03f0b4273a78363e0ee25cb2564656aa1a65ef1
EOF
ansible slave -m copy -a"src=$file dest=/root"
ansible slave -m shell -a"chmod a+x $file"

ansible slave -m shell -a"/root/kubejoin.sh"

kubectl get node -n kube-system
