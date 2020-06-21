#!/bin/bash
spark-sql -f /app/hadoop/fm_sql_test/sqoop.sql

tables=(
T_UserAccount
T_MT4TradesInfo
T_MT4Users
u_user
)
colarrs=(
id,mt4account,brokerid,accountstatus,usertype,userid,accountindex,strategydescription,accounttype
id,ticket,login,brokerid,point
login,brokerid,enable,group,regdate,lastdate,balance,prevmonthbalance,prevbalance,credit,interestrate,equity,margin,margin_level,margin_free,modify_time,gidt,manageraccount
id,nickname
)

start_tm=`date +%s%N`;

num_tables=${#tables[@]}
for (( i=0; i < num_tables; i++ )); do
	name=${tables[i]}
	cols=${colarrs[i]}
	start_tm_tbl=`date +%s%N`;
	hive -e "drop table $name"
	#hadoop fs -rm -r -f /user/hadoop/$name
	#hadoop fs -rm -r -f /user/hive/warehouse/$name
	sqoop import --connect "jdbc:sqlserver://119.23.168.162:52435;database=FM_OS_V3" --username fmreader --password EgyksuQ66TxS --table $name --columns \"$cols\" -m 6 --hcatalog-database default --hcatalog-table $name --create-hcatalog-table --hcatalog-storage-stanza "stored as orcfile"
	end_tm_tbl=`date +%s%N`;
	use_tm_tbl=`echo $end_tm_tbl $start_tm_tbl | awk '{ print ($1 - $2) / 1000000000}'`
	echo "table $name time taken:"
	echo $use_tm_tbl
done

end_tm=`date +%s%N`;
use_tm=`echo $end_tm $start_tm | awk '{ print ($1 - $2) / 1000000000}'`
echo "in total time taken:"
echo $use_tm
