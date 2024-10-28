#cp
#runc_rev=1.1.4
#runc_rev=1.1.3
runc_rev=1.1.12
curl -OL https://github.com/opencontainers/runc/releases/download/v${runc_rev}/runc.amd64
#ansible copy to /root/
#workers
#mv runc.amd64 /usr/local/bin/runc && chmod +x /usr/local/bin/runc
mv runc.amd64 /usr/bin/runc && chmod 755 /usr/bin/runc

#安装cni
#cni_rev=1.1.1
cni_rev=1.5.1
wget -c https://github.com/containernetworking/plugins/releases/download/v${cni_rev}/cni-plugins-linux-amd64-v${cni_rev}.tgz
#ansible copy to /root/
#worker
mkdir -p /opt/cni/bin
tar xvf cni-plugins-linux-amd64-v${cni_rev}.tgz -C /opt/cni/bin/

#cp
#containerd_rev=1.6.10
#containerd_rev=1.6.6
containerd_rev=1.7.22
curl -OL https://github.com/containerd/containerd/releases/download/v${containerd_rev}/containerd-${containerd_rev}-linux-amd64.tar.gz
#ansible copy to /root/
#workers
#cp -r /usr/local /usr/local4containerd
#tar -zxvf containerd-${containerd_rev}-linux-amd64.tar.gz -C /usr/local
cp -r /usr /usr4containerd
tar -zxvf containerd-${containerd_rev}-linux-amd64.tar.gz -C /usr

#cp
#curl -o /etc/systemd/system/containerd.service https://raw.githubusercontent.com/containerd/cri/master/contrib/systemd-units/containerd.service
cat > /etc/systemd/system/containerd.service << EOF
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/usr/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity

[Install]
WantedBy=multi-user.target
EOF
#workers
#ansible copy to /lib/systemd/system/
mkdir /etc/containerd
containerd config default > /etc/containerd/config.toml
#添加了镜像加速配置
#cp
cat > config.toml.registry << EOF
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
          endpoint = ["https://fxy8rj00.mirror.aliyuncs.com","https://docker.registry.cyou","https://docker-cf.registry.cyou","https://dockercf.jsdelivr.fyi","https://docker.jsdelivr.fyi","https://dockertest.jsdelivr.fyi","https://mirror.aliyuncs.com","https://dockerproxy.com","https://mirror.baidubce.com","https://docker.m.daocloud.io","https://docker.nju.edu.cn","https://docker.mirrors.sjtug.sjtu.edu.cn","https://docker.mirrors.ustc.edu.cn","https://mirror.iscas.ac.cn","https://docker.rainbond.cc"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."k8s.gcr.io"]
          endpoint = ["registry.aliyuncs.com/google_containers"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."harbor.my.org:1080"]
          endpoint = ["http://harbor.my.org:1080"]
      [plugins."io.containerd.grpc.v1.cri".registry.configs]
        [plugins."io.containerd.grpc.v1.cri".registry.configs."harbor.my.org:1080".tls]
          insecure_skip_verify = true
          [plugins."io.containerd.grpc.v1.cri".registry.configs."harbor.my.org:1080".auth]
            username = "admin"
            password = "Harbor12345"
EOF
#workers
#ansible copy to /root/
cp /etc/containerd/config.toml /etc/containerd/config.toml.bk
#ansible copy replace-between-2lines.py to /root/
python replace-between-2lines.py /etc/containerd/config.toml /root/config.toml.registry [plugins.\"io.containerd.grpc.v1.cri\".registry] [plugins.\"io.containerd.grpc.v1.cri\".x509_key_pair_streaming]
#ansible all -m shell -a'python replace-between-2lines.py /etc/containerd/config.toml /root/config.toml.registry [plugins.\"io.containerd.grpc.v1.cri\".registry] [plugins.\"io.containerd.grpc.v1.cri\".x509_key_pair_streaming]'
#数据根目录修改到数据盘
#cp
cat > replace-containerd-root.sh << EOF
sed -i 's/root = "\/var\/lib\/containerd"/root = "\/data0\/containerd"/g' /etc/containerd/config.toml
EOF
#ansible copy to /root/
cp /etc/containerd/config.toml /etc/containerd/config.toml.root
/root/replace-containerd-root.sh
cat /etc/containerd/config.toml|grep "root = \""

["https://fxy8rj00.mirror.aliyuncs.com",
"https://docker.registry.cyou",
"https://docker-cf.registry.cyou",
"https://dockercf.jsdelivr.fyi",
"https://docker.jsdelivr.fyi",
"https://dockertest.jsdelivr.fyi",
"https://mirror.aliyuncs.com",
"https://dockerproxy.com",
"https://mirror.baidubce.com",
"https://docker.m.daocloud.io",
"https://docker.nju.edu.cn",
"https://docker.mirrors.sjtug.sjtu.edu.cn",
"https://docker.mirrors.ustc.edu.cn",
"https://mirror.iscas.ac.cn",
"https://docker.rainbond.cc"]

mkdir -p /etc/containerd/certs.d/docker.io
cat > /etc/containerd/certs.d/docker.io/hosts.toml << EOF
server = "https://docker.io"
[host."https://fxy8rj00.mirror.aliyuncs.com"]
  capabilities = ["pull", "resolve"]
[host."https://docker.registry.cyou"]
  capabilities = ["pull", "resolve"]
[host."https://docker-cf.registry.cyou"]
  capabilities = ["pull", "resolve"]
[host."https://dockercf.jsdelivr.fyi"]
  capabilities = ["pull", "resolve"]
[host."https://docker.jsdelivr.fyi"]
  capabilities = ["pull", "resolve"]
[host."https://dockertest.jsdelivr.fyi"]
  capabilities = ["pull", "resolve"]
[host."https://mirror.aliyuncs.com"]
  capabilities = ["pull", "resolve"]
[host."https://dockerproxy.com"]
  capabilities = ["pull", "resolve"]
[host."https://mirror.baidubce.com"]
  capabilities = ["pull", "resolve"]
[host."https://docker.m.daocloud.io"]
  capabilities = ["pull", "resolve"]
[host."https://docker.nju.edu.cn"]
  capabilities = ["pull", "resolve"]
[host."https://docker.mirrors.sjtug.sjtu.edu.cn"]
  capabilities = ["pull", "resolve"]
[host."https://docker.mirrors.ustc.edu.cn"]
  capabilities = ["pull", "resolve"]
[host."https://mirror.iscas.ac.cn"]
  capabilities = ["pull", "resolve"]
[host."https://docker.rainbond.cc"]
  capabilities = ["pull", "resolve"]
EOF
cat > /etc/containerd/certs.d/docker.io/hosts.toml << EOF
server = "https://docker.io"
[host."https://docker.1panel.live"]
  capabilities = ["pull", "resolve"]
EOF
mkdir -p /etc/containerd/certs.d/k8s.gcr.io
cat > /etc/containerd/certs.d/k8s.gcr.io/hosts.toml << EOF
server = "https://registry.aliyuncs.com/google_containers"
[host."https://registry.aliyuncs.com/google_containers"]
  capabilities = ["pull", "resolve"]
  skip_verify = true
EOF
mkdir -p /etc/containerd/certs.d/harbor.my.org:1080
cat > /etc/containerd/certs.d/harbor.my.org:1080/hosts.toml << EOF
server = "http://harbor.my.org:1080"
[host."http://harbor.my.org:1080"]
  capabilities = ["pull", "resolve", "push"]
  skip_verify = true
EOF

cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
EOF

export no_proxy="192.168.3.14,192.168.3.103,192.168.3.6,192.168.3.9,192.168.3.1,192.168.1.1,127.0.0.1"
export NO_PROXY=$no_proxy

kubectl get configmap kubeadm-config -n kube-system -o yaml|grep Subnet
      podSubnet: 192.168.0.0/16
      serviceSubnet: 10.96.0.0/12
mkdir /etc/systemd/system/containerd.service.d
cat > /etc/systemd/system/containerd.service.d/http_proxy.conf << EOF
[Service]
Environment="HTTP_PROXY=http://mmubu:10792/"
Environment="HTTPS_PROXY=http://mmubu:10792/"
Environment="NO_PROXY=localhost,192.168.0.0/16,10.96.0.0/12,10.0.0.0/16,192.168.3.0/24,192.168.1.0/24"
EOF


#启动containerd
#worker
systemctl daemon-reload
systemctl enable containerd
systemctl start containerd
systemctl status containerd
ls /data0/containderd
#安装nerdct
#cp
#nerdctl_rev=1.0.0
#nerdctl_rev=0.22.0
nerdctl_rev=1.3.0
wget -c https://github.com/containerd/nerdctl/releases/download/v${nerdctl_rev}/nerdctl-${nerdctl_rev}-linux-amd64.tar.gz
#ansible copy to /root/
#worker
tar xvf nerdctl-${nerdctl_rev}-linux-amd64.tar.gz
mv nerdctl /usr/local/bin/
nerdctl version
#使用nerdct下载镜像启动容器
#on one work
nerdctl pull nginx
nerdctl run -d -p 80:80 --name nginx --restart=always nginx
nerdctl ps
nerdctl exec -it nginx sh
nerdctl stop nginx
nerdctl ps -a
nerdctl rm nginx
nerdctl ps -a

buildkit_version=0.16.0
wget -c https://github.com/moby/buildkit/releases/download/v${buildkit_version}/buildkit-v${buildkit_version}.linux-amd64.tar.gz
mkdir /usr/local/buildctl
tar xzvf buildkit-v${buildkit_version}.linux-amd64.tar.gz  -C /usr/local/buildctl
ln -s /usr/local/buildctl/bin/buildkitd /usr/local/bin/buildkitd
ln -s /usr/local/buildctl/bin/buildctl /usr/local/bin/buildctl
cat > /etc/systemd/system/buildkit.service << EOF
[Unit]
Description=BuildKit
Documentation=https://github.com/moby/buildkit

[Service]
ExecStart=/usr/local/bin/buildkitd --oci-worker=false --containerd-worker=true

[Install]
WantedBy=multi-user.target
EOF
systemctl enable buildkit --now
systemctl daemon-reload
systemctl start buildkit

