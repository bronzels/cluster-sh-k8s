git clone git@github.com:ilias-sp/ansible-setup-passwordless-ssh.git

#清理过去的ssh文件
#cp
rm -rf ~/.ssh
#mac
sudo rm -rf /var/root/.ssh/
rm -rf /Users/apple/.ssh
#linux
sudo rm -rf /root/.ssh/
#重新生成密钥
ssh-keygen
cat /Users/apple/.ssh/id_rsa.pub
#密钥copy到github
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCuHyZiTGHpGLBJCb/mzrd9CMWe2y2DAbu8cgi/TKAxWt8pr9fI5b69CDklajCPKImBjCwKy9vDnYAdK/16Cd41PWPMrcCgdSmur/+NUjpevdaniMR36ccjMTECwa/9c+bMHdX2zjMvB/x8xwJB4qzRwVXTDNgEJYMBkx+04c80vIKSsrQBpAlMZfXrYXKldknQvALZ71H898ARY/dxHte/LIA6xadYwSuatGst4EdIrgqsjdtgn3uMKrvcOIQfnxsn3khU1frEMD+/osVE9Cdc1qWSuXeqbpV6/sYGzsVt4p+T14eWt5F6xf4JwtascxdhwxGKxOUFhC+ihGYIzQIuFFNwsrorRUr9gu7r4YvJGXZNuckj/5buIWvu+fiSzkQ0xCBvKRE8LKoM85qdX3i458wEdXC+s6EGJ3AAx/SKIyr3dvrfi5yf0EaAP/HO4p9gl8eXgM6x1VgDMyDQ7lgOUARPU0mWdsnWCzXPqvob8e3MbL95xPeAAUpU/z+YnDE= apple@localhost

#被控主机
ansible all -m shell -a"rm -rf /root/.ssh/"

#mac控制点到被控主机，因为sshpass安装路径原因，playbook需要修改
sudo ansible-playbook -i hosts-cp non_interactive/ansible_setup_passwordless_ssh.yml.mac

#被控主机之间免密
sudo ansible-playbook -i hosts non_interactive/ansible_setup_passwordless_ssh.yml.linux

