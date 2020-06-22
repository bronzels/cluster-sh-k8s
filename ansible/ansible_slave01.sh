
#root
mkdir ~/tmp
cd ~

cp /tmp/spark_shared_jars.tar.gz ~/tmp
tar xzvf ~/tmp/spark_shared_jars.tar.gz
ansible slavecdh -m copy -a"src=~/spark_shared_jars dest=~/"

cp /tmp/sqoop.tar.gz ~/tmp
tar xzvf ~/tmp/sqoop.tar.gz

cat << \EOF > deploy_spark_jars.sh
ansible allcdh -m copy -a"src=~/k8sdeploy_dir/spark_jars.tgz dest=~/spark_shared_jars/"
ansible allcdh -m shell -a"cd ~/spark_shared_jars;tar xzvf spark_jars.tgz;cd spark_jars;cp *.jar ../;cd ..;rm -rf spark_jars.tgz spark_jars/"
EOF
chmod a+x deploy_spark_jars.sh

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
