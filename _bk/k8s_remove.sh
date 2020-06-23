ansible allk8s -m shell -a"apt-get remove -y kubelet kubeadm kubectl"
ansible allk8s -m shell -a"apt-get remove -y kubernetes-cni"

ansible allk8sexpcdhcp -m shell -a'docker stop $(docker ps -a -q)'
ansible allk8sexpcdhcp -m shell -a'docker  rm $(docker ps -a -q)'
ansible allk8sexpcdhcp -m shell -a'docker ps -a -q'

#！！！手工，在cdhcp/slave01上，root用户下
docker stop $(docker ps -a | grep k8s_ | awk '{print $1}')
docker ps -a|grep mysql
docker rm $(docker ps -a | grep k8s_ | awk '{print $1}')

docker start $(docker ps -a | grep k8s_ | awk '{print $1}')

rm -rf ~/.kube

ansible allk8s -m shell -a"rm -rf /etc/kubernetes/"
ansible allk8s -m shell -a"rm -rf /etc/systemd/system/kubelet.service.d"
ansible allk8s -m shell -a"rm -rf /etc/systemd/system/kubelet.service"
ansible allk8s -m shell -a"rm -rf /etc/cni"
ansible allk8s -m shell -a"rm -rf /opt/cni"
ansible allk8s -m shell -a"rm -rf /var/lib/etcd"
