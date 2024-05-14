#slaves
#root
fdisk -l|grep "2 TiB"
parted /dev/nvme1n1
:<<EOF
  mklabel gpt
  mkpart p1
    ext4
    1
    2T
  quit
EOF
mkfs.ext4 /dev/nvme1n1p1
mkdir /app2
mount /dev/nvme1n1p1 /app2
df|grep "/app"
#add below in /etc/fstab
