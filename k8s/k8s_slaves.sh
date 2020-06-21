#！！！手工, 新机器加入集群跳过所有cat EOF文件生成步骤

#controlplane/master01
#root

file=/root/kubejoin.sh
rm -f $file
cat >> $file << EOF
kubeadm join api.k8s.at.bronzels:6443 --token 42ypg3.xns4cl9xka8nd2r7 \
    --discovery-token-ca-cert-hash sha256:b88e6e7639e09c48cd358d5db31d0f5c73a59b6d68f15f099b6b9da367f4d5fb
EOF
ansible slavek8s -m copy -a"src=$file dest=/root"
ansible slavek8s -m shell -a"chmod a+x $file"

ansible slavek8s -m shell -a"/root/kubejoin.sh"

kubectl get node -n kube-system
