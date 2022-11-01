tar xzvf go1.19.2.linux-amd64.tar.gz
mv go /usr/local/
echo 'PATH=$PATH:/usr/local/go/bin' >> /etc/profile
cat >> ~/.bash_profile << EOF
export GOPATH=/root/gopath
export GOPROXY=https://goproxy.cn
EOF
