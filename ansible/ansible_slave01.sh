
sudo su -
#root
mkdir ~/released/

#！！！手工，如果重新启动，务必重新mount因为ubuntu18 fstab需要输入UID实在麻烦没有设置，重启要手工加载
:<<EOF
ansible allcdh -m shell -a"mount /dev/nvme0n1p1 /app"
ansible allcdh -m shell -a"df|grep '/app'"
EOF

#scripts for airflow to ssh and execute, or for manual op
mkdir ~/scripts/

#env scripts path set
echo "export PATH=$PATH:$HOME/scripts" >> ~/other-env.sh
#env scripts sourced in .bashrc
echo "source ${HOME}/other-env.sh" >> ~/.bashrc
source ~/.bashrc

