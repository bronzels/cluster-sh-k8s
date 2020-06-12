ansible all -m shell -a"apt-get remove -y kubelet kubeadm kubectl"
ansible all -m shell -a"apt-get remove -y kubernetes-cni"

docker stop $(docker ps -a -q)
docker  rm $(docker ps -a -q)