#！！！手工, 新机器加入集群跳过所有cat EOF文件生成步骤

#controlplane/master01
sudo su -
#root

file=/root/kubejoin.sh
rm -f $file
cat >> $file << EOF
kubeadm join api.k8s.at.bronzels:6443 --token 42ypg3.xns4cl9xka8nd2r7 \
	--discovery-token-ca-cert-hash sha256:87d5e6116f71c12290a0fc62b464684279969e1223c1d628e169452fa302f91b
EOF
ansible slavek8s -m copy -a"src=$file dest=/root"
ansible slavek8s -m shell -a"chmod a+x $file"
ansible slavek8s -m shell -a"/root/kubejoin.sh"
chmod a+x $file
/root/kubejoin.sh

kubectl get node -n kube-system
