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
#centos
file=/etc/resolv.conf
cp ${file} ${file}.bk
cat << \EOF >> ${file}
nameserver 8.8.8.8
nameserver 114.114.114.114
EOF

timedatectl set-timezone Asia/Shanghai
#ubuntu
#设置时区
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
#设置时间自动同步
#/etc/systemd/timesyncd.conf
:<<EOF
#NTP=
NTP=ntp.aliyun.com
EOF
systemctl restart systemd-timesyncd.service
#centos
yum install -y chrony
systemctl start chronyd.service
systemctl enable chronyd.service
systemctl status chronyd.service
file=/etc/chrony.conf
cp ${file} ${file}.bk
sed -i 's/server /#server /g' ${file}
sed -i '/#server 0/i\server ntp.aliyun.com iburst' ${file}
systemctl restart chronyd.service
date

#禁止ipv6
#/etc/default/grub
:<<EOF
#GRUB_CMDLINE_LINUX=""
GRUB_CMDLINE_LINUX="ipv6.disable=1"
EOF
grub2-mkconfig -o /boot/grub2/grub.cfg

#each
#apt-get install -y python

#设置ssh服务
file=/etc/ssh/sshd_config
cp ${file} ${file}.bk
#ubuntu20
sed -i 's@#PermitRootLogin prohibit-password@PermitRootLogin yes@g' ${file}
sed -i 's@#PubkeyAuthentication yes@PubkeyAuthentication yes@g' ${file}
sed -i 's@PasswordAuthentication no@PasswordAuthentication yes@g' ${file}
#centos7
sed -i 's@#PermitRootLogin yes@PermitRootLogin yes@g' ${file}
sed -i 's@#PubkeyAuthentication yes@PubkeyAuthentication yes@g' ${file}
sed -i 's@#PasswordAuthentication yes@PasswordAuthentication yes@g' ${file}

file=/etc/ssh/ssh_config
cp ${file} ${file}.bk
#ubuntu20
sed -i 's@#   StrictHostKeyChecking no@StrictHostKeyChecking no@g' ${file}
#centos7
sed -i 's@#   StrictHostKeyChecking ask@StrictHostKeyChecking no@g' ${file}

ssh-keygen -A
service sshd restart



#！！！手工，aws新机器有2种机器名，如果统一用跳板机的名字做域名，需要修改每台机器的类似ip-10-10-9-83的hostname，然后reboot
#   hk-prod-bigdata-master-8-148
#   ip-10-10-9-83

#备份根分区
tar -czvpf backup-`date +%Y-%m-%d`.tar.gz --one-file-system /
mount|grep "/ "
#dtpct
dd if=/dev/nvme0n1p1 status=progress | gzip -9 > /data0/back-`date +%Y-%m-%d`.img.gz
#mdubu
dd if=/dev/sdc2 status=progress | gzip -9 > /data0/back-`date +%Y-%m-%d`.img.gz
#mdlapubu
dd if=/dev/sda2 status=progress | gzip -9 > /data0/back-`date +%Y-%m-%d`.img.gz

#硬盘对拷，可以安装一台以后，其余对拷的方式，修改/etc/fstab里的挂载硬盘/dev后的设备符号即可
dd if=/dev/sdc of=/dev/sdb bs=6M count=20480 status=progress

120g/6m=20*1024=20480

#fstab加载安装没有包括的分区
fdisk -
blkid /dev/sda3
#UUID=6377-A234 /data0            exfat    defaults,utf8,uid=1000,gid=1000,fmask=0011,dmask=0000              0       0


