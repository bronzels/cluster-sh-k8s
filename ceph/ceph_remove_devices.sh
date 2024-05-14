#！！！如果ceph出现长时间都没有osd pod或者ceph status也显示HEALTH WARN
#！！！！！！首先要把所有已安装的k8s应用全部delete，再卸载rook-ceph
#！！！！！！如果还有应用pvc/image关联上ceph上没法卸载干净

# 卸载ceph以后，需要确保相关设备都已清空或者卸载，否则再次安装会无法操作目标硬盘，导致osd数目不是预期（4），容量也不对。
sudo ansible slavek8s -m shell -a"rm -rf $HOME/rook/ceph"
sudo ansible slavek8s -m shell -a"dmsetup remove_all"
sudo ansible slavek8s -m shell -a"wipefs /dev/nvme1n1"
sudo ansible slavek8s -m shell -a"sgdisk  --zap-all /dev/nvme1n1"
#！！！手工，umount相关mount，再rm -rf（lvremove不行） 相关devmapper，不然重新安装也不行
sudo ansible slavek8s -m shell -a"mount|grep ceph"
sudo ansible slavek8s -m shell -a"mount|grep ceph| awk '{print \$3}'|xargs umount"
sudo ansible slavek8s -m shell -a"mount|grep ceph"
sudo ansible slavek8s -m shell -a"ls /dev|grep ceph"
sudo ansible slavek8s -m shell -a"ls /dev|grep ceph|xargs -I CNAME  sh -c 'rm -rf /dev/CNAME'"
sudo ansible slavek8s -m shell -a"ls /dev|grep ceph"
:<<EOF
sudo ansible slavek8s -m shell -a"fdisk -l|grep ceph"
sudo ansible slavek8s -m shell -a"fdisk -l|grep ceph|xargs -I CNAME  sh -c 'rm -rf /dev/CNAME'"
sudo ansible slavek8s -m shell -a"fdisk -l|grep ceph"
sudo ansible slavek8s -m shell -a"ls /dev/mapper|grep ceph"
sudo ansible slavek8s -m shell -a"ls /dev/mapper|grep ceph|xargs -I CNAME  sh -c 'rm -rf /dev/mapper/CNAME'"
sudo ansible slavek8s -m shell -a"ls /dev/mapper|grep ceph"
EOF
#！！！手工，rm -rf（lvremove不行） 相关devmapper，不然重新安装也不行
