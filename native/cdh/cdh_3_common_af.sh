#root

cd

ansible allcdh -m shell -a"apt-get install -yq cloudera-manager-daemons cloudera-manager-agent cloudera-manager-server"

/opt/cloudera/cm/schema/scm_prepare_database.sh mysql scm scm scm
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql amon amon amon
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql rman rman rman
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql hue hue hue
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql hive hive hive
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql sentry sentry sentry
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql nav nav nav
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql navms navms navms
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql oozie oozie oozie

file=/etc/cloudera-scm-agent/config.ini
cp ${file} ${file}.bk
sed -i 's@server_host=localhost@server_host=10.10.0.31@g' ${file}
ansible slavecdh -m copy -a"src=/etc/cloudera-scm-agent/config.ini dest=/etc/cloudera-scm-agent"

systemctl start cloudera-scm-server
tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log
#会提示无法下载sqoop 404 URI，重新restart就好了
#systemctl restart cloudera-scm-server
systemctl status cloudera-scm-server

ansible allcdh -m shell -a"sysctl vm.swappiness=10"
ansible allcdh -m shell -a"echo 'vm.swappiness=10'>> /etc/sysctl.conf"

#each
ansible allcdh -m shell -a"systemctl start cloudera-scm-agent"
#卸载重装如果slave log提示错误
  #ansible slavecdh -m shell -a"kill -9 、$(pgrep -f supervisord)“
ansible allcdh -m shell -a"tail -100 /var/log/cloudera-scm-agent/cloudera-scm-agent.log"

ansible allcdh -m shell -a"systemctl status cloudera-scm-agent"

