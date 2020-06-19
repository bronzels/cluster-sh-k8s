#root
ansible all -m shell -a"cat /etc/issue"
ansible all -m shell -a"uname -r"
ansible all -m shell -a"free -g"

ansible slave01,slave02,slave03,slave04 -m shell -a"cp /etc/hosts /etc/hosts.bk"
ansible slave01,slave02,slave03,slave04 -m copy -a"src=/etc/hosts dest=/etc"

#ubuntu
#cpscripts for airflow to ssh and execute
rm -rf ~/scripts/
mkdir ~/scripts/

#把本工程的cpscript目录下（不带目录）所有脚本，解压到ubuntu用户的~/scripts/目录
#把项目工程的comcpscript目录下（不带目录）所有脚本，解压到ubuntu用户的~/scripts/目录

#for pika building
:<<EOF
sudo apt-get install -y libzip-dev libsnappy-dev libprotobuf-dev protobuf-compiler bzip2
sudo apt-get install -y libgoogle-glog-dev
sudo apt-get install -y build-essential
#如果机器gcc版本低于gcc4.8，需要切换到gcc4.8或者以上
gcc -v
g++ -v
EOF

cat << \EOF > ~/source.list.ubuntu.16.04
deb http://mirrors.aliyun.com/ubuntu/ trusty main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ trusty-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ trusty-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ trusty-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ trusty-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ trusty main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ trusty-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ trusty-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ trusty-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ trusty-backports main restricted universe multiverse
EOF

#for codis building
:<<EOF
rev=1.12.9
wget -c https://dl.google.com/go/go${rev}.linux-amd64.tar.gz
tar -C ~ -xzf ~/go${rev}.linux-amd64.tar.gz
echo "export PATH=$PATH:$HOME/go/bin" >> ~/.bashrc
mkdir ~/gopath
echo "export GOPATH=$HOME/gopath" >> ~/.bashrc
sudo apt-get install -y autoconf
EOF

#ubuntu
mkdir ~/tmp
cp /tmp/confluent-5.3.2.zip ~/tmp





