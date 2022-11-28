#centos
#安装菜单按tab，输入" vga=711"，在分辨率选择处选择i（最大分辨率）
#dtpct安装需要连接wifi网关，centos7比较老，新机器的以太网驱动缺失

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

#设置镜像
#centos
yum install -y wget
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
yum clean all
yum makecache


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
#centos
file=/etc/default/grub
cp ${file} ${file}.bk
sed -i 's/GRUB_CMDLINE_LINUX="crashkernel=auto rhgb quiet"/GRUB_CMDLINE_LINUX="crashkernel=auto rhgb quiet ipv6.disable=1"/g' ${file}
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



