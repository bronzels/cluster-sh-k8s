#！！！手工，reset之前
:<<EOF
#一定要卸载rook-ceph，并在执行以下命令前后
sudo ansible slavek8s -m shell -a"dmsetup remove_all"
sudo ansible slavek8s -m shell -a"wipefs /dev/nvme1n1"
sudo ansible slavek8s -m shell -a"sgdisk  --zap-all /dev/nvme1n1"
#用以下命令检查是否还有残余ceph mount/dev
sudo ansible slavek8s -m shell -a"mount|grep ceph"
sudo ansible slavek8s -m shell -a"ls /dev|grep ceph"
sudo ansible slavek8s -m shell -a"fdisk -l|grep ceph"
sudo ansible slavek8s -m shell -a"ls /dev/mapper|grep ceph"
EOF

#！！！手工，reset
# 重新执行k8s/k8s.sh自
# ansible allk8s -m shell -a"kubeadm reset -f"
# 以下部分

#！！！手工，reset之后
# 重新生成token
kubeadm token create --print-join-command|sed 's/${LOCAL_IP}/${VIP}/g'
#！！！手工，token copy到脚本，masters重新加入集群，执行k8s/k8s_masters.sh
#！！！手工，token copy到脚本，slaves重新加入集群，执行k8s/k8s_slaves.sh
#！！！手工，重建helm repo
# 执行rm -rf $HOME/.
# 执行helm repo add
#！！！手工，重建image repo
# cd ~/charts/stable/docker-registry
# helm install -f values.yaml dkreg .
#！！！手工，重新安装所有k8s安装软件，可以跳过目录生成，文件生成/修改的步骤，直接执行相应helm install/kubectl apply -f步骤