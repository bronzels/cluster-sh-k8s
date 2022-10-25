#root
#linux

ansible all -m shell -a"apt install -y iptables ethtool socat ipvsadm"

#server sealos runs on
#install helm

wget  https://github.com/labring/sealos/releases/download/v4.1.3/sealos_4.1.3_linux_amd64.tar.gz  && \
    tar -zxvf sealos_4.1.3_linux_amd64.tar.gz sealos &&  chmod +x sealos
mv sealos /usr/bin


sealos run labring/kubernetes:v1.21.14-4.1.3 labring/calico:v3.24.1 \
     --masters 192.168.3.103 \
     --cluster-root /data0/sealos \
     --nodes 192.168.3.6,192.168.3.8 \
     -p asdf
:<<EOF
W1025 09:27:49.889291   48066 strict.go:54] error unmarshaling configuration schema.GroupVersionKind{Group:"kubeproxy.config.k8s.io", Version:"v1alpha1", Kind:"KubeProxyConfiguration"}: error unmarshaling JSON: while decoding JSON: json: unknown field "detectLocal"
W1025 09:27:49.891311   48066 strict.go:54] error unmarshaling configuration schema.GroupVersionKind{Group:"kubelet.config.k8s.io", Version:"v1beta1", Kind:"KubeletConfiguration"}: error unmarshaling JSON: while decoding JSON: json: unknown field "flushFrequency"
[init] Using Kubernetes version: v1.21.14
[preflight] Running pre-flight checks

W1025 09:27:49.889291   48066 strict.go:54] error unmarshaling configuration schema.GroupVersionKind{Group:"kubeproxy.config.k8s.io", Version:"v1alpha1", Kind:"KubeProxyConfiguration"}: error unmarshaling JSON: while decoding JSON: json: unknown field "detectLocal"
W1025 09:27:49.891311   48066 strict.go:54] error unmarshaling configuration schema.GroupVersionKind{Group:"kubelet.config.k8s.io", Version:"v1beta1", Kind:"KubeletConfiguration"}: error unmarshaling JSON: while decoding JSON: json: unknown field "flushFrequency"
[init] Using Kubernetes version: v1.21.14
[preflight] Running pre-flight checks
EOF

#如果需要主节点参与调度
kubectl taint nodes dtpct node-role.kubernetes.io/master:NoSchedule-
kubectl describe node dtpct | grep Taint

sealos reset \
     --masters 192.168.3.103 \
     --nodes 192.168.3.6,192.168.3.8 \
     --cluster-root /data0/sealos \
     -p asdf
#server sealos runs on
ansible all -m shell -a"rm -rf /var/lib/cni;rm -rf /etc/cni;rm -rf /var/lib/etcd;rm -rf /root/.kube;rm -rf /etc/kubernetes/"
ansible all -m shell -a"ipvsadm --clear"
#如果需要删除下载或者恢复的镜像
sealos rmi -f

sealos save -o kubernetes-1.12.14.tar labring/kubernetes:v1.21.14-4.1.3
sealos save -o calico-3.24.1.tar labring/calico:v3.24.1

sealos load -i kubernetes-1.12.14.tar
sealos load -i calico-3.24.1.tar
