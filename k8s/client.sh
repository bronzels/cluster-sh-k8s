#linux
curl -LO "https://dl.k8s.io/release/v1.21.14/bin/linux/amd64/kubectl"
#mac
#curl -LO "https://dl.k8s.io/release/v1.21.14/bin/linux/darwin/kubectl"
chmod a+x kubectl
mv kubectl /usr/bin

#dtpct
tar czvf .kube.tgz .kube/
scp .kube.tgz mmubu:/root/
#mmubu
tar xzvf .kube.tgz
echo "192.168.3.103 apiserver.cluster.local" >> /etc/hosts

#ubuntu
apt install -y bash-completion
apt install mlocate
locate bash_completion
kubectl completion bash > /usr/local/bin/completion.sh
cat /usr/local/bin/completion.sh
chmod 777 /usr/local/bin/completion.sh
echo "source /usr/share/bash-completion/bash_completion" >> /etc/profile
echo "source /usr/local/bin/completion.sh" >> /etc/profile
source /usr/share/bash-completion/bash_completion
source /usr/local/bin/completion.sh


kubectl verion
kubectl cluster-info
kubectl get nodes
kubectl get ns
kubectl get pod -n kube-system

