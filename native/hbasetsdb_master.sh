#login as hadoop
sudo su -
#root
#设置root密码为root
usermod --password $(echo root | openssl passwd -1 -stdin) root
#设置ubuntu密码为ubuntu
usermod --password $(echo hadoop | openssl passwd -1 -stdin) hadoop

file=/etc/ssh/sshd_config
cp ${file} ${file}.bk
sed -i 's@#PermitRootLogin yes@PermitRootLogin yes@g' ${file}
sed -i 's@#PubkeyAuthentication yes@PubkeyAuthentication yes@g' ${file}
sed -i 's@#PasswordAuthentication yes@PasswordAuthentication yes@g' ${file}
sed -i 's@PasswordAuthentication no@#PasswordAuthentication no@g' ${file}

service sshd restart

exit
#hadoop

rm -rf ~/scripts
mkdir ~/scripts

cat << \EOF >> ~/.bashrc
export PATH=$PATH:$HOME/scripts
EOF

#！！！手工，重新登录ubuntu
:<<EOF
hbase shell
  status
  list
  create 't1', {NAME => 'f1', VERSIONS => 1}, {NAME => 'f2', VERSIONS => 1}, {NAME => 'f3', VERSIONS => 1}
  put 't1', 'r4', 'f1:c1', 'v1'
  put 't1', 'r5', 'f2:c2', 'v2'
  put 't1', 'r6', 'f3:c3', 'v3'
  scan 't1'
EOF

