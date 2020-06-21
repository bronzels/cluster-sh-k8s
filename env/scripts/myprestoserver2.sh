export JAVA_HOME=~/jdk;export PATH=~/jdk/bin:$PATH
#!/bin/bash
if [ $1 == "start" ]; then
        echo "!!!master"
/app/home/hadoop/presto-server-2/bin/launcher start
ansible slave -i /etc/ansible/hosts-hadoop -m shell -a"export JAVA_HOME=~/jdk;export PATH=~/jdk/bin:$PATH;/app/home/hadoop/presto-server-2/bin/launcher start"
fi
if [ $1 == "stop" ]; then
/app/home/hadoop/presto-server-2/bin/launcher stop
ansible slave -i /etc/ansible/hosts-hadoop -m shell -a"export JAVA_HOME=~/jdk;export PATH=~/jdk/bin:$PATH;/app/home/hadoop/presto-server-2/bin/launcher stop"
fi
if [ $1 == "status" ]; then
/app/home/hadoop/presto-server-2/bin/launcher status
ansible slave -i /etc/ansible/hosts-hadoop -m shell -a"export JAVA_HOME=~/jdk;export PATH=~/jdk/bin:$PATH;/app/home/hadoop/presto-server-2/bin/launcher status"
fi
