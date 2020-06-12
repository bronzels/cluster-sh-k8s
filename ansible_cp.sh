#master
apt-get install -y ansible
apt-get install -y sshpass
cat <<EOF > /etc/ansible/hosts
master01 ansible_ssh_user=root ansible_ssh_pass=root
master02 ansible_ssh_user=root ansible_ssh_pass=root
slave01 ansible_ssh_user=root ansible_ssh_pass=root
slave02 ansible_ssh_user=root ansible_ssh_pass=root
slave03 ansible_ssh_user=root ansible_ssh_pass=root
slave04 ansible_ssh_user=root ansible_ssh_pass=root
[all]
master01 myhostname="hk-prod-bigdata-master-3-189" myip="10.10.3.189"
master02 myhostname="hk-prod-bigdata-master-3-234" myip="10.10.3.234"
slave01 myhostname="hk-prod-bigdata-slave-0-60" myip="10.10.0.60"
slave02 myhostname="hk-prod-bigdata-slave-11-74" myip="10.10.11.74"
slave03 myhostname="hk-prod-bigdata-slave-8-134" myip="10.10.8.134"
slave04 myhostname="hk-prod-bigdata-slave-8-26" myip="10.10.8.26"
[allexpcp]
master02 myhostname="hk-prod-bigdata-master-3-234" myip="10.10.3.234"
slave01 myhostname="hk-prod-bigdata-slave-0-60" myip="10.10.0.60"
slave02 myhostname="hk-prod-bigdata-slave-11-74" myip="10.10.11.74"
slave03 myhostname="hk-prod-bigdata-slave-8-134" myip="10.10.8.134"
slave04 myhostname="hk-prod-bigdata-slave-8-26" myip="10.10.8.26"
[master]
master01 myhostname="hk-prod-bigdata-master-3-189" myip="10.10.3.189"
master02 myhostname="hk-prod-bigdata-master-3-234" myip="10.10.3.234"
[masterexpcp]
master02 myhostname="hk-prod-bigdata-master-3-234" myip="10.10.3.234"
[slave]
slave01 myhostname="hk-prod-bigdata-slave-0-60" myip="10.10.0.60"
slave02 myhostname="hk-prod-bigdata-slave-11-74" myip="10.10.11.74"
slave03 myhostname="hk-prod-bigdata-slave-8-134" myip="10.10.8.134"
slave04 myhostname="hk-prod-bigdata-slave-8-26" myip="10.10.8.26"
EOF
cat <<EOF > /etc/ansible/hosts-ubuntu
master01 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
master02 ansible_ssh_user=root ansible_ssh_pass=root
slave01 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
slave02 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
slave03 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
slave04 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
[all]
master01 myhostname="hk-prod-bigdata-master-3-189" myip="10.10.3.189"
master02 myhostname="hk-prod-bigdata-master-3-234" myip="10.10.3.234"
slave01 myhostname="hk-prod-bigdata-slave-0-60" myip="10.10.0.60"
slave02 myhostname="hk-prod-bigdata-slave-11-74" myip="10.10.11.74"
slave03 myhostname="hk-prod-bigdata-slave-8-134" myip="10.10.8.134"
slave04 myhostname="hk-prod-bigdata-slave-8-26" myip="10.10.8.26"
[allexpcp]
master02 myhostname="hk-prod-bigdata-master-3-234" myip="10.10.3.234"
slave01 myhostname="hk-prod-bigdata-slave-0-60" myip="10.10.0.60"
slave02 myhostname="hk-prod-bigdata-slave-11-74" myip="10.10.11.74"
slave03 myhostname="hk-prod-bigdata-slave-8-134" myip="10.10.8.134"
slave04 myhostname="hk-prod-bigdata-slave-8-26" myip="10.10.8.26"
[masterexpcp]
master02 myhostname="hk-prod-bigdata-master-3-234" myip="10.10.3.234"
[master]
master01 myhostname="hk-prod-bigdata-master-3-189" myip="10.10.3.189"
master02 myhostname="hk-prod-bigdata-master-3-234" myip="10.10.3.234"
[slave]
slave01 myhostname="hk-prod-bigdata-slave-0-60" myip="10.10.0.60"
slave02 myhostname="hk-prod-bigdata-slave-11-74" myip="10.10.11.74"
slave03 myhostname="hk-prod-bigdata-slave-8-134" myip="10.10.8.134"
slave04 myhostname="hk-prod-bigdata-slave-8-26" myip="10.10.8.26"
EOF
cp /etc/hosts /etc/hosts.bk
cat <<EOF >> /etc/hosts

10.10.3.189 master01
10.10.3.234 master02
10.10.0.60 slave01
10.10.11.74 slave02
10.10.8.134 slave03
10.10.8.26 slave04

10.10.3.189 hk-prod-bigdata-master-3-189
10.10.3.234 hk-prod-bigdata-master-3-234
10.10.0.60 hk-prod-bigdata-slave-0-60
10.10.11.74 hk-prod-bigdata-slave-11-74
10.10.8.134 hk-prod-bigdata-slave-8-134
10.10.8.26 hk-prod-bigdata-slave-8-26

10.10.3.189 api.k8s.at.bronzels
10.10.3.234 api.k8s.at.bronzels

EOF

cp /etc/ansible/ansible.cfg /etc/ansible/ansible.cfg.bk
sed -i 's@#host_key_checking = False@host_key_checking = False@g' /etc/ansible/ansible.cfg

#root
ssh-keygen -t rsa -b 2048 -P '' -f ~/.ssh/id_rsa

cat <<EOF >> ssh-addkey.yml
# ssh-addkey.yml
---
- hosts: all
  gather_facts: no

  tasks:

  - name: install ssh key
    authorized_key: user=root
                    key="{{ lookup('file', '/root/.ssh/id_rsa.pub') }}"
                    state=present
EOF
ssh-keyscan master01 master02 slave01 slave02 slave03 slave04 >> ~/.ssh/known_hosts
ansible-playbook -i /etc/ansible/hosts ~/ssh-addkey.yml

#ubuntu
ssh-keygen -t rsa -b 2048 -P '' -f ~/.ssh/id_rsa

#ubuntu
cat <<EOF >> ssh-addkey.yml
# ssh-addkey.yml
---
- hosts: all
  gather_facts: no

  tasks:

  - name: install ssh key
    authorized_key: user=ubuntu
                    key="{{ lookup('file', '/home/ubuntu/.ssh/id_rsa.pub') }}"
                    state=present
EOF
ssh-keyscan master01 master02 slave01 slave02 slave03 slave04 >> ~/.ssh/known_hosts
ansible-playbook -i /etc/ansible/hosts-ubuntu ~/ssh-addkey.yml

sudo apt install -y unzip zip tar

ansible all -m shell -a"cat /etc/issue"
ansible all -m shell -a"uname -r"

ansible allexpcp -m shell -a"cp /etc/hosts /etc/hosts.bk"
ansible allexpcp -m copy -a"src=/etc/hosts dest=/etc"

#ubuntu
#scripts for airflow to ssh and execute
rm -rf ~/scripts/
mkdir ~/scripts/

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






