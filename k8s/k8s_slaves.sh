#！！！手工, 新机器加入集群跳过所有cat EOF文件生成步骤

#controlplane/master01
sudo su -
#root

#mater节点重新生成token,需要获取新的token
kubeadm token create --ttl 0 --print-join-command

file=/root/kubejoin.sh
rm -f $file
cat >> $file << EOF
kubeadm join api.k8s.at.bronzels:6443 --token 42ypg3.xns4cl9xka8nd2r7 \
	--discovery-token-ca-cert-hash sha256:6473ff544da4bfe4ed6676762d6cf716d6b40c43f18919c8e3f0be4e63a89f6d
EOF
chmod a+x $file
/root/kubejoin.sh
ansible slavek8s -m copy -a"src=$file dest=/root"
ansible slavek8s -m shell -a"chmod a+x $file"
ansible slavek8s -m shell -a"/root/kubejoin.sh"

kubectl get node -n kube-system

