mkdir docker-alternative
cd docker-alternative

cat > /lib/systemd/system/buildkit.socket << EOF
[Unit]
Description=BuildKit
Documentation=https://github.com/moby/buildkit

[Socket]
ListenStream=%t/buildkit/buildkitd.sock

[Install]
WantedBy=sockets.target
EOF
cat > /lib/systemd/system/buildkitd.service << EOF
[Unit]
Description=BuildKit
Documentation=https://github.com/moby/buildkit
# Requires=buildkit.socket
After=buildkit.socket

[Service]
ExecStart=/usr/local/bin/buildkitd --oci-worker=false --containerd-worker=true --addr tcp://0.0.0.0:1234 --addr fd://

[Install]
WantedBy=multi-user.target
EOF
mkdir ~/.docker
cat > ~/.docker/config.json << EOF
{
	"auths": {
		"harbor.my.org:1080": {
			"auth": "YWRtaW46SGFyYm9yMTIzNDU="
		}
	}
}
EOF

#buildkit
wget -c https://github.com/moby/buildkit/releases/download/v0.10.5/buildkit-v0.10.5.linux-amd64.tar.gz
tar -zxvf buildkit-v0.10.5.linux-amd64.tar.gz
# 拷贝服务端与客户端二进制文件到环境变量目录
cp bin/buildkitd bin/buildctl /usr/local/bin/

systemctl daemon-reload
systemctl enable --now buildkitd
systemctl status buildkitd

#nerdctl
wget -c https://github.com/containerd/nerdctl/releases/download/v0.22.2/nerdctl-0.22.2-linux-amd64.tar.gz
tar -zxvf nerdctl-0.22.2-linux-amd64.tar.gz
cp nerdctl /usr/local/bin/
nerdctl version

