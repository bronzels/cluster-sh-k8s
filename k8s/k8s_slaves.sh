#！！！手工, 新机器加入集群跳过所有cat EOF文件生成步骤

#controlplane/master01
sudo su -
#root

file=/root/kubejoin.sh
rm -f $file
cat >> $file << EOF
kubeadm join api.k8s.at.bronzels:6443 --token 42ypg3.xns4cl9xka8nd2r7 \
	--discovery-token-ca-cert-hash sha256:83edebebdda897241bd07783f863d91f253e310eb8927d83f2979e29e90bb587
EOF
chmod a+x $file
/root/kubejoin.sh
ansible slavek8s -m copy -a"src=$file dest=/root"
ansible slavek8s -m shell -a"chmod a+x $file"
ansible slavek8s -m shell -a"/root/kubejoin.sh"

kubectl get node -n kube-system
