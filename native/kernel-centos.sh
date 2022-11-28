#因为nvidia的cuda对os的版本gcc都有要求，升级取消
ansible slave -m shell -a""

#centos
#升级kernel
uname -r
#导入key
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
#安装elrepo源
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
#使用以下命令列出可用的内核相关包，如下图：
yum --disablerepo="*" --enablerepo="elrepo-kernel" list available
#最新ml-6.0.8版本realtek网卡编译不过
#yum -y --enablerepo=elrepo-kernel install kernel-ml.x86_64 kernel-ml-devel.x86_64
yum -y --enablerepo=elrepo-kernel install kernel-lt.x86_64 kernel-lt-devel.x86_64
#yum -y --enablerepo=elrepo-kernel install kernel-ml-doc kernel-ml-headers kernel-ml-tools kernel-ml-tools-libs kernel-ml-tools-libs-devel
yum -y --enablerepo=elrepo-kernel install kernel-lt-doc kernel-lt-headers kernel-lt-tools kernel-lt-tools-libs kernel-lt-tools-libs-devel
#control point
mkdir ml-5.15
cd ml-5.15
wget https://dl.lamp.sh/kernel/el8/kernel-ml-5.15.63-1.el8.x86_64.rpm \
https://dl.lamp.sh/kernel/el8/kernel-ml-headers-5.15.63-1.el8.x86_64.rpm \
https://dl.lamp.sh/kernel/el8/kernel-ml-devel-5.15.63-1.el8.x86_64.rpm \
https://dl.lamp.sh/kernel/el8/kernel-ml-tools-5.15.63-1.el8.x86_64.rpm \
https://dl.lamp.sh/kernel/el8/kernel-ml-tools-libs-5.15.63-1.el8.x86_64.rpm \
https://dl.lamp.sh/kernel/el8/kernel-ml-tools-libs-devel-5.15.63-1.el8.x86_64.rpm
ansible slave -m copy -a"src=ml-5.15  dest=/root/"
yum localinstall ml-5.15/* -y
cp /etc/default/grub /etc/default/grub.kernel-upgrade-bk
echo "set -e;awk -F\' ' \$1==\"menuentry \" {print i++ \" : \" \$2}' /etc/grub2.cfg" > show-boot.sh
ansible slave -m copy -a"src=show-boot.sh  dest=/root/"
ansible slave -m shell -a"chmod a+x /root/show-boot.sh"
ansible slave -m shell -a"/root/show-boot.sh"
sed -i 's/GRUB_DEFAULT=saved/GRUB_DEFAULT=0/g' /etc/default/grub
sed -i 's/GRUB_DEFAULT=0/GRUB_DEFAULT=1/g' /etc/default/grub
cat /etc/default/grub | grep GRUB_DEFAULT
grub2-mkconfig -o /boot/grub2/grub.cfg

#kernel小版本升级
yum update -y
rpm -qa|grep kernel
#重启
sync;reboot now
yum remove -y kernel-3.10.0-1160.el7.x86_64
yum install -y kernel-devel kernel-headers kernel-tools-libs-devel
rpm -qa|grep kernel

#添加 epel 扩展源
yum -y install epel-release
yum install -y wget bzip2

#卸载kernel
rpm -qa|grep kernel
:<<EOF
kernel-lt-devel-5.4.224-1.el7.elrepo.x86_64
kernel-tools-libs-3.10.0-1160.el7.x86_64
kernel-3.10.0-1160.el7.x86_64
kernel-tools-3.10.0-1160.el7.x86_64
kernel-lt-5.4.224-1.el7.elrepo.x86_64
EOF
yum remove -y devtoolset-7-gcc devtoolset-7-make devtoolset-8-gcc devtoolset-8-make devtoolset-9-gcc devtoolset-9-make devtoolset-10-gcc devtoolset-10-make devtoolset-11-gcc devtoolset-11-make
#yum remove -y kernel-lt-doc kernel-lt-headers kernel-lt-tools kernel-lt-tools-libs kernel-lt-tools-libs-devel
yum remove -y kernel-ml-doc kernel-ml-headers kernel-ml-tools kernel-ml-tools-libs kernel-ml-tools-libs-devel
#yum remove -y kernel-lt kernel-lt-devel
yum remove -y kernel-ml kernel-ml-devel
rpm -qa|grep kernel


