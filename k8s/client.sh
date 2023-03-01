if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    os=darwin
    MYHOME=/Volumes/data
    SED=gsed
    bin=/Users/apple/bin
else
    echo "Assuming linux by default."
    #linux
    os=linux
    MYHOME=~
    SED=sed
    bin=/usr/local/bin
fi

#linux
curl -LO "https://dl.k8s.io/release/v1.21.14/bin/linux/amd64/kubectl"
chmod a+x kubectl
mv kubectl /usr/bin
#mac
curl -LO "https://dl.k8s.io/release/v1.21.14/bin/darwin/amd64/kubectl"
chmod a+x kubectl
sudo mv kubectl /Users/apple/bin

#dtpct
cd /root
tar czvf .kube.tgz .kube/
#linux
scp .kube.tgz mmubu:/root/
#从控制点mmubu发起
cd
scp root@dtpct:/root/.kube.tgz ./
rm -rf .kube
tar xzvf .kube.tgz
sudo echo "192.168.3.14 apiserver.cluster.local" >> /etc/hosts

#ubuntu
apt install -y bash-completion
apt install mlocate
locate bash_completion
kubectl completion bash > /usr/local/bin/completion.sh
cat /usr/local/bin/completion.sh
chmod 777 /usr/local/bin/completion.sh
echo 'alias k=kubectl' >> /etc/profile
echo "source /usr/share/bash-completion/bash_completion" >> /etc/profile
sed -i 's/kubectl/k/g' /usr/share/bash-completion/bash_completion
echo "source /usr/local/bin/completion.sh" >> /etc/profile
source /usr/share/bash-completion/bash_completion
source /usr/local/bin/completion.sh

#mac
type _init_completion
brew install bash-completion@2
echo 'export BASH_COMPLETION_COMPAT_DIR="/usr/local/etc/bash_completion.d"' >> ~/.bash_profile
echo '[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"' >> ~/.bash_profile
#重新进入终端窗口
type _init_completion
#将补全脚本添加到目录中
kubectl completion bash >/usr/local/etc/bash_completion.d/kubectl
echo 'source /usr/local/etc/bash_completion.d/kubectl' >>~/.bash_profile
#设置别名
echo 'alias k=kubectl' >>~/.bash_profile
echo 'complete -o default -F __start_kubectl k' >>~/.bash_profile
#重新进入终端窗口

kubectl verion
kubectl cluster-info
kubectl get nodes
kubectl get ns
kubectl get pod -A

#重启或者某个node断网引起evicted无法恢复
kubectl get pod -A -o wide|grep Evicted|awk '{print $1}{print $2}'|xargs -n2 sh -c 'kubectl delete pod "$2" -n "$1"' sh
kubectl get pods -A |grep -v 'Running\|ContainerCreating\Pending' |awk '{printf("kubectl delete pods %s -n %s --force --grace-period=0\n", $2,$1)}' | /bin/bash

#删除pod
kubectl delete pod spark-test -n spark-operator --force --grace-period=0
kubectl patch pod spark-test -n spark-operator -p '{"metadata":{"finalizers":null}}'

cat << \EOF > ${bin}/kjobreset.sh
#!/bin/bash

NAMESPACE=$1
JOB=$2

kubectl get job $JOB -n $NAMESPACE -o json |
  jq 'del(.spec.selector)' |
  jq 'del(.spec.template.metadata.labels)' |
  kubectl replace --force -f - >/dev/null
kubectl wait --for=condition=complete job/$JOB -n $NAMESPACE --timeout 120s >/dev/null
EOF
chmod a+x ${bin}/kjobreset.sh

