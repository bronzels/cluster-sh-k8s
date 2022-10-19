#root

wget  https://github.com/labring/sealos/releases/download/v4.1.3/sealos_4.1.3_linux_amd64.tar.gz  && \
    tar -zxvf sealos_4.1.3_linux_amd64.tar.gz sealos &&  chmod +x sealos && mv sealos /usr/bin

sealos run labring/kubernetes:v1.21.14-4.1.3 labring/calico:v3.24.1 \
     --masters 192.168.3.103 \
     --cluster-root /data0/sealos \
     --nodes 192.168.3.6,192.168.3.8 \
     -p asdf

sealos reset \
     --masters 192.168.3.103 \
     --nodes 192.168.3.6,192.168.3.8 \
     --cluster-root /data0/sealos \
     -p asdf


