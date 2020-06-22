#on each
#  master01
#  deploy01

#root
apt-get install -y ansible
apt-get install -y sshpass
cat <<EOF > /etc/ansible/hosts
hk-prod-bigdata-master-7-44 ansible_ssh_user=root ansible_ssh_pass=root
hk-prod-bigdata-master-14-114 ansible_ssh_user=root ansible_ssh_pass=root
hk-prod-bigdata-slave-0-234 ansible_ssh_user=root ansible_ssh_pass=root
hk-prod-bigdata-slave-10-34 ansible_ssh_user=root ansible_ssh_pass=root
hk-prod-bigdata-slave-3-3 ansible_ssh_user=root ansible_ssh_pass=root
hk-prod-bigdata-slave-5-226 ansible_ssh_user=root ansible_ssh_pass=root

[all]
hk-prod-bigdata-master-7-44
hk-prod-bigdata-master-14-114
hk-prod-bigdata-slave-0-234
hk-prod-bigdata-slave-10-34
hk-prod-bigdata-slave-3-3
hk-prod-bigdata-slave-5-226

[newgrp]
hk-prod-bigdata-slave-10-34
hk-prod-bigdata-slave-5-226

[allk8s]
hk-prod-bigdata-master-7-44
hk-prod-bigdata-master-14-114
hk-prod-bigdata-slave-0-234
hk-prod-bigdata-slave-10-34
hk-prod-bigdata-slave-3-3
hk-prod-bigdata-slave-5-226
[allk8sexpcdhcp]
hk-prod-bigdata-master-7-44
hk-prod-bigdata-master-14-114
hk-prod-bigdata-slave-10-34
hk-prod-bigdata-slave-3-3
hk-prod-bigdata-slave-5-226
[allk8sexpcp]
hk-prod-bigdata-master-14-114
hk-prod-bigdata-slave-0-234
hk-prod-bigdata-slave-10-34
hk-prod-bigdata-slave-3-3
hk-prod-bigdata-slave-5-226
[masterk8s]
hk-prod-bigdata-master-7-44
hk-prod-bigdata-master-14-114
[masterk8sexpcp]
hk-prod-bigdata-master-14-114
[slavek8s]
hk-prod-bigdata-slave-0-234
hk-prod-bigdata-slave-10-34
hk-prod-bigdata-slave-3-3
hk-prod-bigdata-slave-5-226

[allcdh]
hk-prod-bigdata-slave-0-234
hk-prod-bigdata-slave-10-34
hk-prod-bigdata-slave-3-3
hk-prod-bigdata-slave-5-226
[slavecdh]
hk-prod-bigdata-slave-10-34
hk-prod-bigdata-slave-3-3
hk-prod-bigdata-slave-5-226
EOF
cat <<EOF > /etc/ansible/hosts-ubuntu
hk-prod-bigdata-master-7-44 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
hk-prod-bigdata-master-14-114 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
hk-prod-bigdata-slave-0-234 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
hk-prod-bigdata-slave-10-34 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
hk-prod-bigdata-slave-3-3 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
hk-prod-bigdata-slave-5-226 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu

[all]
hk-prod-bigdata-master-7-44
hk-prod-bigdata-master-14-114
hk-prod-bigdata-slave-0-234
hk-prod-bigdata-slave-10-34
hk-prod-bigdata-slave-3-3
hk-prod-bigdata-slave-5-226

[newgrp]
hk-prod-bigdata-slave-10-34
hk-prod-bigdata-slave-5-226

[allk8s]
hk-prod-bigdata-master-7-44
hk-prod-bigdata-master-14-114
hk-prod-bigdata-slave-0-234
hk-prod-bigdata-slave-10-34
hk-prod-bigdata-slave-3-3
hk-prod-bigdata-slave-5-226
[allk8sexpcdhcp]
hk-prod-bigdata-master-7-44
hk-prod-bigdata-master-14-114
hk-prod-bigdata-slave-10-34
hk-prod-bigdata-slave-3-3
hk-prod-bigdata-slave-5-226
[allk8sexpcp]
hk-prod-bigdata-master-14-114
hk-prod-bigdata-slave-0-234
hk-prod-bigdata-slave-10-34
hk-prod-bigdata-slave-3-3
hk-prod-bigdata-slave-5-226
[masterk8s]
hk-prod-bigdata-master-7-44
hk-prod-bigdata-master-14-114
[masterk8sexpcp]
hk-prod-bigdata-master-14-114
[slavek8s]
hk-prod-bigdata-slave-0-234
hk-prod-bigdata-slave-10-34
hk-prod-bigdata-slave-3-3
hk-prod-bigdata-slave-5-226

[allcdh]
hk-prod-bigdata-slave-0-234
hk-prod-bigdata-slave-10-34
hk-prod-bigdata-slave-3-3
hk-prod-bigdata-slave-5-226
[slavecdh]
hk-prod-bigdata-slave-10-34
hk-prod-bigdata-slave-3-3
hk-prod-bigdata-slave-5-226
EOF
cp /etc/hosts /etc/hosts.bk
cat <<EOF >> /etc/hosts

10.10.7.44 master01

10.10.7.44 hk-prod-bigdata-master-7-44
10.10.14.114 hk-prod-bigdata-master-14-114

10.10.0.234 hk-prod-bigdata-slave-0-234
10.10.10.34 hk-prod-bigdata-slave-10-34
10.10.3.3 hk-prod-bigdata-slave-3-3
10.10.5.226 hk-prod-bigdata-slave-5-226

10.10.7.44 api.k8s.at.bronzels
10.10.14.114 api.k8s.at.bronzels

EOF

:<<EOF
master01 hk-prod-bigdata-master-7-44
master02 hk-prod-bigdata-master-14-114

slave01 hk-prod-bigdata-slave-0-234
slave02 hk-prod-bigdata-slave-10-34
slave03 hk-prod-bigdata-slave-3-3
slave04 hk-prod-bigdata-slave-5-226

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
ssh-keyscan hk-prod-bigdata-master-7-44 hk-prod-bigdata-master-14-114 hk-prod-bigdata-slave-0-234 hk-prod-bigdata-slave-10-34 hk-prod-bigdata-slave-3-3 hk-prod-bigdata-slave-5-226 >> ~/.ssh/known_hosts
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
ssh-keyscan hk-prod-bigdata-master-7-44 hk-prod-bigdata-master-14-114 hk-prod-bigdata-slave-0-234 hk-prod-bigdata-slave-10-34 hk-prod-bigdata-slave-3-3 hk-prod-bigdata-slave-5-226 >> ~/.ssh/known_hosts
ansible-playbook -i /etc/ansible/hosts-ubuntu ~/ssh-addkey.yml

#root
sed -i 's@ ansible_ssh_pass=root@@g' /etc/ansible/hosts
sed -i 's@ ansible_ssh_pass=ubuntu@@g' /etc/ansible/hosts-ubuntu
sudo apt install -y unzip zip tar make

#root
ansible all -m shell -a"ls ~"

#ubuntu
ansible all -i /etc/ansible/hosts-ubuntu -m shell -a"ls ~"
