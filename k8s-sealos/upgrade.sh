cat > /etc/yum.repos.d/labring.repo << EOF
[fury]
name=labring Yum Repo
baseurl=https://yum.fury.io/labring/
enabled=1
gpgcheck=0
EOF
:<<EOF
yum clean all
yum install sealos
sealos pull labring/kubernetes:v1.25.7
sealos save -o kubernetes-1.25.7.tar labring/kubernetes:v1.25.7
sealos pull labring/calico:v3.24.5
sealos save -o calico-3.24.5.tar labring/calico:v3.24.5
sealos load -i kubernetes-1.25.7.tar
sealos load -i calico-3.24.5.tar
EOF

sealos pull registry.cn-hangzhou.aliyuncs.com/bronzels/docker.io-labring-kubernetes-v1.25.7:1.0
sealos pull registry.cn-hangzhou.aliyuncs.com/bronzels/docker.io-labring-calico-v3.24.5:1.0

sealos run registry.cn-hangzhou.aliyuncs.com/bronzels/docker.io-labring-kubernetes-v1.25.7:1.0 registry.cn-hangzhou.aliyuncs.com/bronzels/docker.io-labring-calico-v3.24.5:1.0 \
     --masters 192.168.3.14 \
     --env cluster-root=/data0/sealos \
     --nodes 192.168.3.103,192.168.3.6 \
     -p asdf
