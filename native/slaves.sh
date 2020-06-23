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
