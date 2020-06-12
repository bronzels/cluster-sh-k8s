#each
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
