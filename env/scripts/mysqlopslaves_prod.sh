content=$1

hosts=(
pro-hbase01
pro-hbase02
pro-hbase04
pro-hbase03
pro-hbase04
)
ports=(
3316
3316
3318
3316
3316
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

