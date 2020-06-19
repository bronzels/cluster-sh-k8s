#each from ubuntu
sudo su -
#root
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


#slaves
#root
fdisk -l|grep "2 TiB"
parted /dev/nvme0n1
:<<EOF
  mklabel gpt
  mkpart p1
    ext3
    1
    2T
  quit
EOF
mkfs.ext4 /dev/nvme0n1p1
mkdir /app
mount /dev/nvme0n1p1 /app
df|grep "/app"
#add below in /etc/fstab
