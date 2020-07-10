#on each
#  master01
#  deploy01

#root
apt-get install -y ansible
apt-get install -y sshpass
cat <<EOF > /etc/ansible/hosts
hk-prod-bigdata-master-9-83 ansible_ssh_user=root ansible_ssh_pass=root
hk-prod-bigdata-master-8-148 ansible_ssh_user=root ansible_ssh_pass=root
hk-prod-bigdata-slave-1-62 ansible_ssh_user=root ansible_ssh_pass=root
hk-prod-bigdata-slave-11-47 ansible_ssh_user=root ansible_ssh_pass=root
hk-prod-bigdata-slave-13-106 ansible_ssh_user=root ansible_ssh_pass=root
hk-prod-bigdata-slave-3-169 ansible_ssh_user=root ansible_ssh_pass=root

[all]
hk-prod-bigdata-master-9-83
hk-prod-bigdata-master-8-148
hk-prod-bigdata-slave-1-62
hk-prod-bigdata-slave-11-47
hk-prod-bigdata-slave-13-106
hk-prod-bigdata-slave-3-169

[newgrp]

[allk8s]
hk-prod-bigdata-master-9-83
hk-prod-bigdata-master-8-148
hk-prod-bigdata-slave-1-62
hk-prod-bigdata-slave-11-47
hk-prod-bigdata-slave-13-106
hk-prod-bigdata-slave-3-169

[allk8sexpcdhcp]
hk-prod-bigdata-master-9-83
hk-prod-bigdata-master-8-148
hk-prod-bigdata-slave-11-47
hk-prod-bigdata-slave-13-106
hk-prod-bigdata-slave-3-169

[allk8sexpcp]
hk-prod-bigdata-master-8-148
hk-prod-bigdata-slave-1-62
hk-prod-bigdata-slave-11-47
hk-prod-bigdata-slave-13-106
hk-prod-bigdata-slave-3-169

[masterk8s]
hk-prod-bigdata-master-9-83
hk-prod-bigdata-master-8-148

[masterk8sexpcp]
hk-prod-bigdata-master-8-148

[slavek8s]
hk-prod-bigdata-slave-1-62
hk-prod-bigdata-slave-11-47
hk-prod-bigdata-slave-13-106
hk-prod-bigdata-slave-3-169

[allcdh]
hk-prod-bigdata-slave-1-62
hk-prod-bigdata-slave-11-47
hk-prod-bigdata-slave-13-106
hk-prod-bigdata-slave-3-169

[slavecdh]
hk-prod-bigdata-slave-11-47
hk-prod-bigdata-slave-13-106
hk-prod-bigdata-slave-3-169

EOF
cat <<EOF > /etc/ansible/hosts-ubuntu
hk-prod-bigdata-master-9-83 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
hk-prod-bigdata-master-8-148 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
hk-prod-bigdata-slave-1-62 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
hk-prod-bigdata-slave-11-47 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
hk-prod-bigdata-slave-13-106 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
hk-prod-bigdata-slave-3-169 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu

[all]
hk-prod-bigdata-master-9-83
hk-prod-bigdata-master-8-148
hk-prod-bigdata-slave-1-62
hk-prod-bigdata-slave-11-47
hk-prod-bigdata-slave-13-106
hk-prod-bigdata-slave-3-169

[newgrp]

[allk8s]
hk-prod-bigdata-master-9-83
hk-prod-bigdata-master-8-148
hk-prod-bigdata-slave-1-62
hk-prod-bigdata-slave-11-47
hk-prod-bigdata-slave-13-106
hk-prod-bigdata-slave-3-169

[allk8sexpcdhcp]
hk-prod-bigdata-master-9-83
hk-prod-bigdata-master-8-148
hk-prod-bigdata-slave-11-47
hk-prod-bigdata-slave-13-106
hk-prod-bigdata-slave-3-169

[allk8sexpcp]
hk-prod-bigdata-master-8-148
hk-prod-bigdata-slave-1-62
hk-prod-bigdata-slave-11-47
hk-prod-bigdata-slave-13-106
hk-prod-bigdata-slave-3-169

[masterk8s]
hk-prod-bigdata-master-9-83
hk-prod-bigdata-master-8-148

[masterk8sexpcp]
hk-prod-bigdata-master-8-148

[slavek8s]
hk-prod-bigdata-slave-1-62
hk-prod-bigdata-slave-11-47
hk-prod-bigdata-slave-13-106
hk-prod-bigdata-slave-3-169

[allcdh]
hk-prod-bigdata-slave-1-62
hk-prod-bigdata-slave-11-47
hk-prod-bigdata-slave-13-106
hk-prod-bigdata-slave-3-169

[slavecdh]
hk-prod-bigdata-slave-11-47
hk-prod-bigdata-slave-13-106
hk-prod-bigdata-slave-3-169

EOF
cp /etc/hosts /etc/hosts.bk
cat <<EOF >> /etc/hosts

10.10.9.83 master01

10.10.9.83 hk-prod-bigdata-master-9-83
10.10.8.148 hk-prod-bigdata-master-8-148

10.10.1.62 hk-prod-bigdata-slave-1-62
10.10.11.47 hk-prod-bigdata-slave-11-47
10.10.13.106 hk-prod-bigdata-slave-13-106
10.10.3.169 hk-prod-bigdata-slave-3-169

10.10.9.83 api.k8s.at.bronzels
10.10.8.148 api.k8s.at.bronzels

EOF

:<<EOF
master01 hk-prod-bigdata-master-7-44
slave01 hk-prod-bigdata-slave-1-62

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
ssh-keyscan hk-prod-bigdata-master-9-83 hk-prod-bigdata-master-8-148 hk-prod-bigdata-slave-1-62 hk-prod-bigdata-slave-11-47 hk-prod-bigdata-slave-13-106 hk-prod-bigdata-slave-3-169
ansible-playbook -i /etc/ansible/hosts ~/ssh-addkey.yml

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
ssh-keyscan hk-prod-bigdata-master-9-83 hk-prod-bigdata-master-8-148 hk-prod-bigdata-slave-1-62 hk-prod-bigdata-slave-11-47 hk-prod-bigdata-slave-13-106 hk-prod-bigdata-slave-3-169
ansible-playbook -i /etc/ansible/hosts-ubuntu ~/ssh-addkey.yml

sudo su -
#root
sed -i 's@ ansible_ssh_pass=root@@g' /etc/ansible/hosts
sed -i 's@ ansible_ssh_pass=ubuntu@@g' /etc/ansible/hosts-ubuntu

#used for unpacking/installing
apt-get install -y unzip zip tar make

#used for
# cdh db initialization
# airflow ssh to cp to stop/start mysql slave sync
apt-get install -y mysql-client

#root
ansible all -m shell -a"ls ~"

exit
#ubuntu
ansible all -i /etc/ansible/hosts-ubuntu -m shell -a"ls ~"
