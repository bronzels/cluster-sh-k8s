#!/bin/bash
#spark-sql -f /app/hadoop/fm_sql_test/sqoop.sql

start_tm=`date +%s%N`;

server=$2
user=$3
pswd=$4

#jdbc:mysql://rm-wz905j9253s6l04l6.mysql.rds.aliyuncs.com:3306/mt4_pico
#liuxiangbin
#m1njooUE04vc

#jdbc:mysql://pro-hbase01:3306/fm
#fm
#fm

#num_tables=${#tables[@]}
#for (( i=0; i < num_tables; i++ )); do
	#name=${tables[i]}
	name=$1
	prefix=$5
	#cols=${colarrs[i]}
	#cols=$2
	start_tm_tbl=`date +%s%N`;
	hive -e "drop table $prefix$name"
	#hadoop fs -rm -r -f /user/hadoop/$name
	#hadoop fs -rm -r -f /user/hive/warehouse/$name
	sqoop import --connect \"$server\" --username $user --password $pswd --table $name -m 6 --hcatalog-database default --hcatalog-table $prefix$name --create-hcatalog-table --hcatalog-storage-stanza "stored as orcfile"
	end_tm_tbl=`date +%s%N`;
	use_tm_tbl=`echo $end_tm_tbl $start_tm_tbl | awk '{ print ($1 - $2) / 1000000000}'`
	echo "table $name time taken:"
	echo $use_tm_tbl
#done

end_tm=`date +%s%N`;
use_tm=`echo $end_tm $start_tm | awk '{ print ($1 - $2) / 1000000000}'`
echo "in total time taken:"
echo $use_tm
