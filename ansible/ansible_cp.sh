#on each
#  master01
#  deploy01

#root
apt-get install -y ansible
apt-get install -y sshpass
cat <<EOF > /etc/ansible/hosts
hk-prod-bigdata-master-5-13 ansible_ssh_user=root ansible_ssh_pass=root
hk-prod-bigdata-master-4-158 ansible_ssh_user=root ansible_ssh_pass=root
hk-prod-bigdata-slave-0-31 ansible_ssh_user=root ansible_ssh_pass=root
hk-prod-bigdata-slave-13-53 ansible_ssh_user=root ansible_ssh_pass=root
hk-prod-bigdata-slave-3-240 ansible_ssh_user=root ansible_ssh_pass=root
hk-prod-bigdata-slave-5-105 ansible_ssh_user=root ansible_ssh_pass=root

[all]
hk-prod-bigdata-master-5-13
hk-prod-bigdata-master-4-158
hk-prod-bigdata-slave-0-31
hk-prod-bigdata-slave-13-53
hk-prod-bigdata-slave-3-240
hk-prod-bigdata-slave-5-105

[newgrp]

[allk8s]
hk-prod-bigdata-master-5-13
hk-prod-bigdata-master-4-158
hk-prod-bigdata-slave-0-31
hk-prod-bigdata-slave-13-53
hk-prod-bigdata-slave-3-240
hk-prod-bigdata-slave-5-105

[allk8sexpcdhcp]
hk-prod-bigdata-master-5-13
hk-prod-bigdata-master-4-158
hk-prod-bigdata-slave-13-53
hk-prod-bigdata-slave-3-240
hk-prod-bigdata-slave-5-105

[allk8sexpcp]
hk-prod-bigdata-master-4-158
hk-prod-bigdata-slave-0-31
hk-prod-bigdata-slave-13-53
hk-prod-bigdata-slave-3-240
hk-prod-bigdata-slave-5-105

[masterk8s]
hk-prod-bigdata-master-5-13
hk-prod-bigdata-master-4-158

[masterk8sexpcp]
hk-prod-bigdata-master-4-158

[slavek8s]
hk-prod-bigdata-slave-0-31
hk-prod-bigdata-slave-13-53
hk-prod-bigdata-slave-3-240
hk-prod-bigdata-slave-5-105

[allcdh]
hk-prod-bigdata-slave-0-31
hk-prod-bigdata-slave-13-53
hk-prod-bigdata-slave-3-240
hk-prod-bigdata-slave-5-105

[slavecdh]
hk-prod-bigdata-slave-13-53
hk-prod-bigdata-slave-3-240
hk-prod-bigdata-slave-5-105

EOF
cat <<EOF > /etc/ansible/hosts-ubuntu
hk-prod-bigdata-master-5-13 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
hk-prod-bigdata-master-4-158 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
hk-prod-bigdata-slave-0-31 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
hk-prod-bigdata-slave-13-53 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
hk-prod-bigdata-slave-3-240 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
hk-prod-bigdata-slave-5-105 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu

[all]
hk-prod-bigdata-master-5-13
hk-prod-bigdata-master-4-158
hk-prod-bigdata-slave-0-31
hk-prod-bigdata-slave-13-53
hk-prod-bigdata-slave-3-240
hk-prod-bigdata-slave-5-105

[newgrp]

[allk8s]
hk-prod-bigdata-master-5-13
hk-prod-bigdata-master-4-158
hk-prod-bigdata-slave-0-31
hk-prod-bigdata-slave-13-53
hk-prod-bigdata-slave-3-240
hk-prod-bigdata-slave-5-105

[allk8sexpcdhcp]
hk-prod-bigdata-master-5-13
hk-prod-bigdata-master-4-158
hk-prod-bigdata-slave-13-53
hk-prod-bigdata-slave-3-240
hk-prod-bigdata-slave-5-105

[allk8sexpcp]
hk-prod-bigdata-master-4-158
hk-prod-bigdata-slave-0-31
hk-prod-bigdata-slave-13-53
hk-prod-bigdata-slave-3-240
hk-prod-bigdata-slave-5-105

[masterk8s]
hk-prod-bigdata-master-5-13
hk-prod-bigdata-master-4-158

[masterk8sexpcp]
hk-prod-bigdata-master-4-158

[slavek8s]
hk-prod-bigdata-slave-0-31
hk-prod-bigdata-slave-13-53
hk-prod-bigdata-slave-3-240
hk-prod-bigdata-slave-5-105

[allcdh]
hk-prod-bigdata-slave-0-31
hk-prod-bigdata-slave-13-53
hk-prod-bigdata-slave-3-240
hk-prod-bigdata-slave-5-105

[slavecdh]
hk-prod-bigdata-slave-13-53
hk-prod-bigdata-slave-3-240
hk-prod-bigdata-slave-5-105

EOF
cp /etc/hosts /etc/hosts.bk
cat <<EOF >> /etc/hosts

10.10.5.13 master01

10.10.5.13 hk-prod-bigdata-master-5-13
10.10.4.158 hk-prod-bigdata-master-4-158

10.10.0.31 hk-prod-bigdata-slave-0-31
10.10.13.53 hk-prod-bigdata-slave-13-53
10.10.3.240 hk-prod-bigdata-slave-3-240
10.10.5.105 hk-prod-bigdata-slave-5-105

10.10.5.13 api.k8s.at.bronzels
10.10.4.158 api.k8s.at.bronzels

EOF

:<<EOF
master01 hk-prod-bigdata-master-7-44
slave01 hk-prod-bigdata-slave-0-31

EOF
cp /etc/ansible/ansible.cfg /etc/ansible/ansible.cfg.bk
sed -i 's@#host_key_checking = False@host_key_checking = False@g' /etc/ansible/ansible.cfg

#root
ssh-keygen -t rsa -b 2048 -P '' -f ~/.ssh/id_rsa

cat <<EOF > ssh-addkey.yml
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
ssh-keyscan hk-prod-bigdata-master-5-13 hk-prod-bigdata-master-4-158 hk-prod-bigdata-slave-0-31 hk-prod-bigdata-slave-13-53 hk-prod-bigdata-slave-3-240 hk-prod-bigdata-slave-5-105
ansible-playbook -i /etc/ansible/hosts ~/ssh-addkey.yml

exit
#ubuntu
ssh-keygen -t rsa -b 2048 -P '' -f ~/.ssh/id_rsa

#ubuntu
cat <<EOF > ssh-addkey.yml
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
ssh-keyscan hk-prod-bigdata-master-5-13 hk-prod-bigdata-master-4-158 hk-prod-bigdata-slave-0-31 hk-prod-bigdata-slave-13-53 hk-prod-bigdata-slave-3-240 hk-prod-bigdata-slave-5-105
ansible-playbook -i /etc/ansible/hosts-ubuntu ~/ssh-addkey.yml

sudo su -
#root
sed -i 's@ ansible_ssh_pass=root@@g' /etc/ansible/hosts
sed -i 's@ ansible_ssh_pass=ubuntu@@g' /etc/ansible/hosts-ubuntu

#used for unpacking/installing
apt install -y unzip zip tar make

#used for
# cdh db initialization
# airflow ssh to cp to stop/start mysql slave sync
apt-get install -y mysql-client

sudo su -
#root
ansible all -m shell -a"ls ~"

exit
#ubuntu
ansible all -i /etc/ansible/hosts-ubuntu -m shell -a"ls ~"
