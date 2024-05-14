#确保内核yum update升级到小版本最新
wget -c https://downloadmirror.intel.com/15817/eng/e1000e-3.8.4.tar.gz
tar xzvf e1000e-3.8.4.tar.gz
cd e1000e-3.8.4/
cd src

#确保gcc，make/kernel-devel，kernel-headers已经安装
yum install -y gcc gcc-c++ make

cd /usr/src
ln -s kernels/3.10.0-1160.80.1.el7.x86_64 linux
cd -
make ## 编译驱动器源码
make install ## 安装相应的驱动器程序
depmod -a #测试驱动程序，没报错说明正确。
modprobe e1000e
#查看是否已经加载：
lsmod | grep e1000e
ip a
#断开wifi连接
nmtui
#重启看以太网是否缺省连接
sync;reboot now

#把内核需要update小版本升级到最新，不然虽然驱动加载成功，还是没有网卡
uname -r
#重启从3.10.0-1160.el7.x86_64切换到3.10.0-1160.80.1.el7.x86_64
#必要的话用升级大版本方式刷新grub2，
uname -r
