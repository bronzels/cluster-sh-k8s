#如果网络无法启动，重新启动到原来内核版本，更新驱动
yum install -y pciutils
#查看芯片版本
lspci -v
#r8169
#下载驱动
#https://www.realtek.com/zh-tw/component/zoo/category/network-interface-controllers-10-100-1000m-gigabit-ethernet-pci-express-software
tar xzvf r8168-8.050.03.tar.bz2
chmod a+x r8168-8.050.03/autorun.sh
ansible slave -m copy -a"src=r8168-8.050.03 dest=/root/"
rm -rf /root/r8168-8.050.03
yum install -y centos-release-scl
yum install -y tar devtoolset-7-gcc devtoolset-7-make devtoolset-7-gcc-c++ devtoolset-8-gcc devtoolset-8-make devtoolset-8-gcc-c++ devtoolset-9-gcc devtoolset-9-make devtoolset-9-gcc-c++ devtoolset-10-gcc devtoolset-10-make devtoolset-10-gcc-c++ devtoolset-11-gcc devtoolset-11-make devtoolset-11-gcc-c++
#逐个主机单独执行
scl enable devtoolset-8 bash
echo "source scl_source enable devtoolset-8" >> /root/.bashrc
#sed -i 's/devtoolset-7/devtoolset-9/g' /root/.bashrc
cat /root/.bashrc | grep devtoolset
gcc -v
make -v

sync;reboot now
#逐个主机单独执行
uname -r
cd r8168-8.050.03
./autorun.sh
