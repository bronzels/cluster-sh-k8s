tar xzvf go1.19.2.linux-amd64.tar.gz
sudo mv go /usr/local/
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
cat >> ~/.bashrc << EOF
export GOPATH=$HOME/gopath
export GOPROXY=https://goproxy.cn
EOF

#exfat格式化和挂载支持
yum install -y epel-release
rpm -v --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm
yum install -y exfat-utils fuse-exfat

#cmake
#ubuntu
#安装libssl1.11依赖
echo "deb http://security.ubuntu.com/ubuntu focal-security main" | sudo tee /etc/apt/sources.list.d/focal-security.list
apt install libssl1.1
#添加签名密钥
wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | sudo apt-key add -
#将存储库添加到您的源列表并进行更新
sudo apt-add-repository 'deb https://apt.kitware.com/ubuntu/ bionic main'
sudo apt-get update
#然后再使用apt安装就是最新版本的cmake啦
sudo apt install cmake
