host=$1
port=$2
content=$3

if [ ${content} == "behind" ]; then
mysql -h ${host} -P${port} -uroot -p123456 -e "show slave status\G"|grep Seconds_Behind_Master
else
mysql -h ${host} -P${port} -uroot -p123456 -e "show slave status\G"|grep -E "Slave_IO_State|Slave_IO_Running|Slave_SQL_Running|Last_Errno|Last_Error|Skip_Counter|Seconds_Behind_Master|Last_IO_Errno|Last_IO_Error|Last_SQL_Errno|Last_SQL_Error|SQL_Delay|SQL_Remaining_Delay|Slave_SQL_Running_State|Master_Retry_Count"
fi

