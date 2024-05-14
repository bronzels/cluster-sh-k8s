content=$3
host=$1
port=$2

if [ ${content} == "start" ]; then
mysql -h ${host} -P${port} -uliuxiangbin -pm1njooUE04vc -e "start slave;"
else
mysql -h ${host} -P${port} -uliuxiangbin -pm1njooUE04vc -e "stop slave;"
fi

