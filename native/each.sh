#each from ubuntu
sudo su -
#root
#设置root密码为root
usermod --password $(echo root | openssl passwd -1 -stdin) root
#设置ubuntu密码为ubuntu
usermod --password $(echo ubuntu | openssl passwd -1 -stdin) ubuntu

#each
apt-get install -y python

file=/etc/ssh/sshd_config
cp ${file} ${file}.bk
sed -i 's@#PermitRootLogin prohibit-password@PermitRootLogin yes@g' ${file}
sed -i 's@#PubkeyAuthentication yes@PubkeyAuthentication yes@g' ${file}
sed -i 's@PasswordAuthentication no@PasswordAuthentication yes@g' ${file}
service sshd restart

#！！！手工，aws新机器有2种机器名，如果统一用跳板机的名字做域名，需要修改每台机器的类似ip-10-10-9-83的hostname，然后reboot
#   hk-prod-bigdata-master-8-148
#   ip-10-10-9-83
