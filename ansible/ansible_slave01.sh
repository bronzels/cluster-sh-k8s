
#root
mkdir ~/tmp
cd ~

cp /tmp/spark_shared_jars.tar.gz ~/tmp
tar xzvf ~/tmp/spark_shared_jars.tar.gz
ansible slavecdh -m copy -a"src=~/spark_shared_jars dest=~/"

#！！！手工，如果重新启动，务必重新mount因为ubuntu18 fstab需要输入UID实在麻烦没有设置，重启要手工加载
ansible allcdh -m shell -a"mount /dev/nvme0n1p1 /app"
ansible allcdh -m shell -a"df|grep '/app'"

cp /tmp/sqoop.tar.gz ~/tmp
tar xzvf ~/tmp/sqoop.tar.gz

#root
#scripts for airflow to ssh and execute
rm -rf ~/scripts/
mkdir ~/scripts/

echo "export PATH=$PATH:$HOME/scripts" >> ~/.bashrc
#！！！手工，重新登录ubuntu

#把本工程的script目录下（不带目录）所有脚本，解压到root用户的~/scripts/目录
cd ~/scripts;unzip /tmp/scripts.zip
#把项目工程的comscript目录下（不带目录）所有脚本，解压到root用户的~/scripts/目录
cd ~/scripts;unzip /tmp/comscripts.zip
