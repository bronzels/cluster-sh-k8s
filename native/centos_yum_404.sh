rm -f /etc/yum.repos.d/*.*
rpm -qa yum yum-3.4.3-150.el7.centos.noarch
rpm -qa | grep yum | xargs rpm -e --nodeps
rpm -qa yum
wget -c https://mirrors.aliyun.com/centos/7/os/x86_64/Packages/yum-3.4.3-168.el7.centos.noarch.rpm?spm=a2c6h.25603864.0.0.4c332137dvZIEE
wget -c https://mirrors.aliyun.com/centos/7/os/x86_64/Packages/yum-metadata-parser-1.1.4-10.el7.x86_64.rpm?spm=a2c6h.25603864.0.0.4c332137dvZIEE
wget -c https://mirrors.aliyun.com/centos/7/os/x86_64/Packages/yum-plugin-fastestmirror-1.1.31-54.el7_8.noarch.rpm?spm=a2c6h.25603864.0.0.4c332137dvZIEE
rpm -ivh yum-*
rpm -qa yum
rpm --import http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-7
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
yum clean all
yum makecache
yum install -y vim
yum remove -y vim