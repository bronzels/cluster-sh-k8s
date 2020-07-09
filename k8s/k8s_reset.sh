#！！！手工，reset之前
:<<EOF
#！！！如果ceph出现长时间都没有osd pod或者ceph status也显示HEALTH WARN
#！！！！！！首先要把所有已安装的k8s应用全部delete，再卸载rook-ceph
#！！！！！！如果还有应用pvc/image关联上ceph上没法卸载干净
#卸载rook-ceph，并在执行以下命令前后
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
sudo ansible allk8s -m shell -a"kubeadm reset -f"

sudo ansible allk8s -m shell -a"ipvsadm --clear"

ansible allk8s -m shell -a"rm -rf /root/.kube"
sudo ansible allk8s -m shell -a"rm -rf /root/.kube"
sudo ansible allk8s -m shell -a"rm -rf /etc/kubernetes/*"
sudo ansible allk8s -m shell -a"rm -rf /home/ubuntu/.kube"

#！！！手工，reset之后
# 重新生成token
kubeadm token create --print-join-command|sed 's/${LOCAL_IP}/${VIP}/g'
#！！！手工，token copy到脚本，masters重新加入集群，执行k8s/k8s_masters.sh
#！！！手工，token copy到脚本，slaves重新加入集群，执行k8s/k8s_slaves.sh
#！！！手工，重建helm repo
rm -rf $HOME/.cache/helm
rm -rf $HOME/.config/helm
rm -rf $HOME/.local/share/helm
# 执行helm repo add
#！！！手工，重建image repo
 cd ~/charts/stable/docker-registry
helm install -f values.yaml dkreg .
#！！！手工，重新安装所有k8s安装软件，可以跳过目录生成，文件生成/修改的步骤，直接执行相应helm install/kubectl apply -f步骤