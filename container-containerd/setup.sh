#cp
runc_rev=1.1.4
#runc_rev=1.1.3
curl -OL https://github.com/opencontainers/runc/releases/download/v${runc_rev}/runc.amd64
#ansible copy to /root/
#workers
#mv runc.amd64 /usr/local/bin/runc && chmod +x /usr/local/bin/runc
mv runc.amd64 /usr/bin/runc && chmod +x /usr/bin/runc

#cp
containerd_rev=1.6.10
#containerd_rev=1.6.6
curl -OL https://github.com/containerd/containerd/releases/download/v${containerd_rev}/containerd-${containerd_rev}-linux-amd64.tar.gz
#ansible copy to /root/
#workers
#cp -r /usr/local /usr/local4containerd
#tar -zxvf containerd-${containerd_rev}-linux-amd64.tar.gz -C /usr/local
cp -r /usr /usr4containerd
tar -zxvf containerd-${containerd_rev}-linux-amd64.tar.gz -C /usr

#cp
#curl -o /etc/systemd/system/containerd.service https://raw.githubusercontent.com/containerd/cri/master/contrib/systemd-units/containerd.service
cat > containerd.service << EOF
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
          endpoint = ["https://xxxxxx.mirror.aliyuncs.com", "https://registry-1.docker.io"]
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

#启动containerd
#worker
systemctl daemon-reload
systemctl enable containerd
systemctl start containerd
systemctl status containerd
ls /data0/containderd
#安装nerdct
#cp
nerdctl_rev=1.0.0
#nerdctl_rev=0.22.0
wget -c https://github.com/containerd/nerdctl/releases/download/v${nerdctl_rev}/nerdctl-${nerdctl_rev}-linux-amd64.tar.gz
#ansible copy to /root/
#worker
tar xvf nerdctl-${nerdctl_rev}-linux-amd64.tar.gz
mv nerdctl /usr/local/bin/
nerdctl version
#安装cni
cni_rev=1.1.1
wget -c https://github.com/containernetworking/plugins/releases/download/v${cni_rev}/cni-plugins-linux-amd64-v${cni_rev}.tgz
#ansible copy to /root/
#worker
mkdir -p /opt/cni/bin
tar xvf cni-plugins-linux-amd64-v${cni_rev}.tgz -C /opt/cni/bin/
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
