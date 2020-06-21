content=$1

hosts=(
10.0.0.244
10.0.0.244
10.3.0.227
10.0.0.244
)
ports=(
3306
3307
4444
3308
)


if [ ${content} == "start" ]; then
for i in $(seq 0 $[${#hosts[@]}-1]); do
host=${hosts[$i]}
port=${ports[$i]}
mysql -h ${host} -P${port} -uliuxiangbin -pm1njooUE04vc -e "start slave;"
mysql -h ${host} -P${port} -uliuxiangbin -pm1njooUE04vc -e "show slave status\G"|grep -E "Slave_IO_State|Slave_IO_Running|Slave_SQL_Running|Last_Errno|Last_Error|Skip_Counter|Seconds_Behind_Master|Last_IO_Errno|Last_IO_Error|Last_SQL_Errno|Last_SQL_Error|SQL_Delay|SQL_Remaining_Delay|Slave_SQL_Running_State|Master_Retry_Count"
done
else
for i in $(seq 0 $[${#hosts[@]}-1]); do
host=${hosts[$i]}
port=${ports[$i]}
mysql -h ${host} -P${port} -uliuxiangbin -pm1njooUE04vc -e "stop slave;"
mysql -h ${host} -P${port} -uliuxiangbin -pm1njooUE04vc -e "show slave status\G"|grep -E "Slave_IO_State|Slave_IO_Running|Slave_SQL_Running|Last_Errno|Last_Error|Skip_Counter|Seconds_Behind_Master|Last_IO_Errno|Last_IO_Error|Last_SQL_Errno|Last_SQL_Error|SQL_Delay|SQL_Remaining_Delay|Slave_SQL_Running_State|Master_Retry_Count"
done
fi

