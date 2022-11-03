#设置密码
#each from ubuntu
sudo su -
#root
#设置root密码为asdf
usermod --password $(echo asdf | openssl passwd -1 -stdin) root
#设置hadoop密码为hadoop
usermod --password $(echo hadoop | openssl passwd -1 -stdin) hadoop

#sudo免密
#each
#/etc/sudoers
:<<EOF
%sudo   ALL=(ALL:ALL) ALL
sudo    ALL=(ALL:ALL) PASSWD: ALL
EOF

#su免密
#each
#/etc/pam.d/su
:<<EOF
# auth       sufficient pam_wheel.so trust
auth       sufficient pam_wheel.so trust
EOF
groupadd wheel
usermod -G wheel hadoop

#禁止swap
#/etc/fstab
#/swap.img      none    swap    sw      0       0

#设置dns
#ubuntu防止重启丢失dns设置
mv /etc/resolv.conf /etc/resolv.conf.bk
ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
#/etc/systemd/resolved.conf
:<<EOF
#DNS=
DNS=8.8.8.8 114.114.114.114 192.168.3.1
EOF
systemctl restart systemd-resolved.service
cat /etc/resolv.conf

#设置时区
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
#ubuntu设置时间自动同步
#/etc/systemd/timesyncd.conf
:<<EOF
#NTP=
NTP=ntp.aliyun.com
EOF
systemctl restart systemd-timesyncd.service
date

#禁止ipv6
#/etc/default/grub
:<<EOF
#GRUB_CMDLINE_LINUX=""
GRUB_CMDLINE_LINUX="ipv6.disable=1"
EOF

#each
#apt-get install -y python

#设置ssh服务
file=/etc/ssh/sshd_config
cp ${file} ${file}.bk
sed -i 's@#PermitRootLogin prohibit-password@PermitRootLogin yes@g' ${file}
sed -i 's@#PubkeyAuthentication yes@PubkeyAuthentication yes@g' ${file}
sed -i 's@PasswordAuthentication no@PasswordAuthentication yes@g' ${file}

file=/etc/ssh/ssh_config
cp ${file} ${file}.bk
sed -i 's@#   StrictHostKeyChecking no@StrictHostKeyChecking no@g' ${file}

ssh-keygen -A
service sshd restart

#！！！手工，aws新机器有2种机器名，如果统一用跳板机的名字做域名，需要修改每台机器的类似ip-10-10-9-83的hostname，然后reboot
#   hk-prod-bigdata-master-8-148
#   ip-10-10-9-83

#备份根分区
tar -czvpf backup-`date +%Y-%m-%d`.tar.gz --one-file-system /
mount|grep /dev
#dtpct
dd if=/dev/sdc3 | gzip -9 > back-`date +%Y-%m-%d`.img.gz
#mdubu
dd if=/dev/sdb3 | gzip -9 > back-`date +%Y-%m-%d`.img.gz
#mdlapubu
dd if=/dev/sda3 | gzip -9 > back-`date +%Y-%m-%d`.img.gz