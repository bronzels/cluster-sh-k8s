:<<\EOF
wget  https://github.com/labring/sealos/releases/download/v4.1.3/sealos_4.1.3_linux_amd64.tar.gz  && \
    tar -zxvf sealos_4.1.3_linux_amd64.tar.gz sealos &&  chmod +x sealos && mv sealos /usr/bin

sealos run labring/kubernetes:v1.21.14-4.1.3 labring/calico:v3.24.1 \
     --masters 192.168.3.103 \
     --nodes 192.168.3.6,192.168.3.8 \
     -p asdf

sealos run \
	--masters 192.168.3.103 \
  --nodes 192.168.3.6,192.168.3.8 \
	--pkg-url /home/hadoop//kube1.21.8.tar.gz \
	--version v1.21.8

EOF

wget -c https://sealer.oss-cn-beijing.aliyuncs.com/sealer-latest.tar.gz && \
    tar -xvf sealer-latest.tar.gz -C /usr/bin

sealer run kubernetes:v1.21.14 \
  --masters 192.168.3.103 \
  --nodes 192.168.3.6,192.168.3.8 \
  --passwd asdf
