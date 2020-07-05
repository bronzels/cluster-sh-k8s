#！！！手工, 新机器加入集群跳过所有cat EOF文件生成步骤

#controlplane/master01
sudo su -
#root

file=/root/kubejoin.sh
rm -f $file
cat >> $file << EOF
kubeadm join api.k8s.at.bronzels:6443 --token 42ypg3.xns4cl9xka8nd2r7 \
    --discovery-token-ca-cert-hash sha256:6f6f511f1000d92df7a49fa68aa66afb35cc2b9e8201b28210c00db527600fac
EOF
ansible slavek8s -m copy -a"src=$file dest=/root"
ansible slavek8s -m shell -a"chmod a+x $file"

ansible slavek8s -m shell -a"/root/kubejoin.sh"

exit
kubectl get node -n kube-system
