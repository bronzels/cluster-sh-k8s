tar xzvf go1.19.2.linux-amd64.tar.gz
mv go /usr/local/
echo 'PATH=$PATH:/usr/local/go/bin' >> /etc/profile
cat >> ~/.bash_profile << EOF
export GOPATH=/root/gopath
export GOPROXY=https://goproxy.cn
EOF

#exfat格式化和挂载支持
yum install -y epel-release
rpm -v --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm
yum install -y exfat-utils fuse-exfat
