:<<EOF
！！！注意事项
1，系统盘备份必须用另外一个启动安装盘或者u盘完整linux启动，让要备份的系统盘处于不活动的状态。
2，可以整盘备份如果根分区基本就是系统盘大小，也可以单独备份根分区。
3，对拷以前，目标盘如果分区和备份img不一致，最好删除分区再copy。如果目标盘的size比备份img大，更不能分区，多出来的size暂时未分配不会影响恢复。
4，备份和恢复时，最好只有启动盘一个硬盘上电。多个硬盘，sd后面的字母分配到指定系统盘上可能会变化，不同机器之间复制时盘符会对不上。
5，/etc/fstab里用/dev/sda而不是blkid来加载，并暂时取消其他硬盘加载，blkid不同机器之间复制一定会不同，用sda会避免这个问题。
6，可能会有硬盘只要上电就会抢占系统盘sda的情况，可以把抢占sda的硬盘先不上电。sata3的机器和固态都插上时，固定会给机械分配sda，更换sata3插口线无法解决。
EOF

#安装bzip2
#centos
yum install -y bzip2

cd /data0
#dtpct
echo "dd if=/dev/nvme0n1p2 status=progress | bzip2 > /data0/sysbk/back-nvme0n1p2-`date +%Y-%m-%d`.img.bz" > backup.sh
bzip2 -dc /data0/sysbk/back-nvme0n1p2-2022-11-28.img.bz | dd of=/dev/nvme0n1p2 status=progress
#mdubu
echo "dd if=/dev/sdb2 status=progress | bzip2 > /data0/back-sdb2-`date +%Y-%m-%d`.img.bz" > backup.sh
bzip2 -cd /data0/back-sdb2-2022-11-28.img.bz | dd of=/dev/sdb2 status=progress
#mdlapubu
echo "dd if=/dev/sda2 status=progress | bzip2 > /data0/back-sda2-`date +%Y-%m-%d`.img.bz" > backup.sh
bzip2 -cd /data0/back-sda2-2022-11-28.img.bz | dd of=/dev/sda2 status=progress

chmod a+x backup.sh
./backup.sh > backup.log 2>&1 &
tail -f backup.log

#1硬盘对拷，可以安装一台以后，其余对拷的方式，修改/etc/fstab里的挂载硬盘/dev后的设备符号即可
dd if=/dev/sdc of=/dev/sdb bs=6M count=20480 status=progress
#2硬盘对拷，启动进入以后，修改host名
hostnamectl set-hostname 主机名

120g/6m=20*1024=20480

#fstab加载安装没有包括的分区
fdisk -l
blkid /dev/sda3
#UUID=6377-A234 /data0            exfat    defaults,utf8,uid=1000,gid=1000,fmask=0011,dmask=0000              0       0
