#on each
#  master01
#  deploy01

#root
apt-get install -y ansible
apt-get install -y sshpass
:<<EOF
master01 ansible_ssh_user=root ansible_ssh_pass=root
deploy01 ansible_ssh_user=root ansible_ssh_pass=root
slave01 ansible_ssh_user=root ansible_ssh_pass=root
slave02 ansible_ssh_user=root ansible_ssh_pass=root
slave03 ansible_ssh_user=root ansible_ssh_pass=root
slave04 ansible_ssh_user=root ansible_ssh_pass=root
EOF
cat <<EOF > /etc/ansible/hosts
hk-prod-bigdata-master-6-127 ansible_ssh_user=root ansible_ssh_pass=root
hk-prod-bigdata-master-11-84 ansible_ssh_user=root ansible_ssh_pass=root
hk-prod-bigdata-slave-1-245 ansible_ssh_user=root ansible_ssh_pass=root
hk-prod-bigdata-slave-3-30 ansible_ssh_user=root ansible_ssh_pass=root
hk-prod-bigdata-slave-5-41 ansible_ssh_user=root ansible_ssh_pass=root
hk-prod-bigdata-slave-8-134 ansible_ssh_user=root ansible_ssh_pass=root

[all]
hk-prod-bigdata-master-6-127
hk-prod-bigdata-master-11-84
hk-prod-bigdata-slave-1-245
hk-prod-bigdata-slave-3-30
hk-prod-bigdata-slave-5-41
hk-prod-bigdata-slave-8-134

[allk8s]
hk-prod-bigdata-master-6-127
hk-prod-bigdata-master-11-84
hk-prod-bigdata-slave-1-245
hk-prod-bigdata-slave-3-30
hk-prod-bigdata-slave-5-41
hk-prod-bigdata-slave-8-134
[allk8sexpcdhcp]
hk-prod-bigdata-master-6-127
hk-prod-bigdata-master-11-84
hk-prod-bigdata-slave-3-30
hk-prod-bigdata-slave-5-41
hk-prod-bigdata-slave-8-134
[allk8sexpcp]
hk-prod-bigdata-master-11-84
hk-prod-bigdata-slave-1-245
hk-prod-bigdata-slave-3-30
hk-prod-bigdata-slave-5-41
hk-prod-bigdata-slave-8-134
[masterk8s]
hk-prod-bigdata-master-6-127
hk-prod-bigdata-master-11-84
[masterk8sexpcp]
hk-prod-bigdata-master-11-84
[slavek8s]
hk-prod-bigdata-slave-1-245
hk-prod-bigdata-slave-3-30
hk-prod-bigdata-slave-5-41
hk-prod-bigdata-slave-8-134

[allcdh]
hk-prod-bigdata-slave-1-245
hk-prod-bigdata-slave-3-30
hk-prod-bigdata-slave-5-41
hk-prod-bigdata-slave-8-134
[slavecdh]
hk-prod-bigdata-slave-3-30
hk-prod-bigdata-slave-5-41
hk-prod-bigdata-slave-8-134
EOF
:<<EOF
master01 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
deploy01 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
slave01 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
slave02 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
slave03 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
slave04 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
EOF
cat <<EOF > /etc/ansible/hosts-ubuntu
hk-prod-bigdata-master-6-127 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
hk-prod-bigdata-master-11-84 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
hk-prod-bigdata-slave-1-245 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
hk-prod-bigdata-slave-3-30 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
hk-prod-bigdata-slave-5-41 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu
hk-prod-bigdata-slave-8-134 ansible_ssh_user=ubuntu ansible_ssh_pass=ubuntu


[all]
hk-prod-bigdata-master-6-127
hk-prod-bigdata-master-11-84
hk-prod-bigdata-slave-1-245
hk-prod-bigdata-slave-3-30
hk-prod-bigdata-slave-5-41
hk-prod-bigdata-slave-8-134

[allk8s]
hk-prod-bigdata-master-6-127
hk-prod-bigdata-master-11-84
hk-prod-bigdata-slave-1-245
hk-prod-bigdata-slave-3-30
hk-prod-bigdata-slave-5-41
hk-prod-bigdata-slave-8-134
[allk8sexpcdhcp]
hk-prod-bigdata-master-6-127
hk-prod-bigdata-master-11-84
hk-prod-bigdata-slave-3-30
hk-prod-bigdata-slave-5-41
hk-prod-bigdata-slave-8-134
[allk8sexpcp]
hk-prod-bigdata-master-11-84
hk-prod-bigdata-slave-1-245
hk-prod-bigdata-slave-3-30
hk-prod-bigdata-slave-5-41
hk-prod-bigdata-slave-8-134
[masterk8s]
hk-prod-bigdata-master-6-127
hk-prod-bigdata-master-11-84
[masterk8sexpcp]
hk-prod-bigdata-master-11-84
[slavek8s]
hk-prod-bigdata-slave-1-245
hk-prod-bigdata-slave-3-30
hk-prod-bigdata-slave-5-41
hk-prod-bigdata-slave-8-134

[allcdh]
hk-prod-bigdata-slave-1-245
hk-prod-bigdata-slave-3-30
hk-prod-bigdata-slave-5-41
hk-prod-bigdata-slave-8-134
[slavecdh]
hk-prod-bigdata-slave-3-30
hk-prod-bigdata-slave-5-41
hk-prod-bigdata-slave-8-134
EOF
cp /etc/hosts /etc/hosts.bk
cat <<EOF >> /etc/hosts

10.10.6.127 hk-prod-bigdata-master-6-127

10.10.11.84 hk-prod-bigdata-master-11-84

10.10.1.245 hk-prod-bigdata-slave-1-245
10.10.3.30 hk-prod-bigdata-slave-3-30
10.10.5.41 hk-prod-bigdata-slave-5-41
10.10.8.134 hk-prod-bigdata-slave-8-134

10.10.6.127 api.k8s.at.bronzels

EOF

:<<EOF
master01 hk-prod-bigdata-master-6-127
master02 hk-prod-bigdata-master-11-84

slave01 hk-prod-bigdata-slave-1-245
slave01 hk-prod-bigdata-slave-3-30
slave01 hk-prod-bigdata-slave-5-41
slave01 hk-prod-bigdata-slave-8-134

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
ssh-keyscan hk-prod-bigdata-master-6-127 hk-prod-bigdata-master-11-84 hk-prod-bigdata-slave-1-245 hk-prod-bigdata-slave-3-30 hk-prod-bigdata-slave-5-41 hk-prod-bigdata-slave-8-134 >> ~/.ssh/known_hosts
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
ssh-keyscan hk-prod-bigdata-master-6-127 hk-prod-bigdata-master-11-84 hk-prod-bigdata-slave-1-245 hk-prod-bigdata-slave-3-30 hk-prod-bigdata-slave-5-41 hk-prod-bigdata-slave-8-134 >> ~/.ssh/known_hosts
ansible-playbook -i /etc/ansible/hosts-ubuntu ~/ssh-addkey.yml

#root
sed -i 's@ ansible_ssh_pass=root@@g' /etc/ansible/hosts
sed -i 's@ ansible_ssh_pass=ubuntu@@g' /etc/ansible/hosts-ubuntu
sudo apt install -y unzip zip tar make

#root
ansible all -m shell -a"ls ~"

#ubuntu
ansible all -i /etc/ansible/hosts-ubuntu -m shell -a"ls ~"
