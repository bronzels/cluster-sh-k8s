#!/bin/bash
#spark-sql -f /app/hadoop/fm_sql_test/sqoop.sql

max_modify_time=$1
prefix=$2

tables=(
t_mt4trades
t_followorders
td_followorders
t_useraccount
t_mt4users
t_followreport
td_followreport
s_follower
t_traderscore
u_user
)
colarrs=(
id,ticket,login,brokerid,symbol,cmd,volume,open_time,close_time,modify_time,open_price,close_price,profit,swaps,commission,standardsymbol,standardlots,comment,pips
id,masteraccount,masterbrokerid,masterorderid,followaccount,followbrokerid,followorderid,status,closetime,updatetime
id,masteraccount,masterbrokerid,masterorderid,followaccount,followbrokerid,followorderid,status,closetime,updatetime
id,mt4account,brokerid,accountstatus,usertype,userid,accountindex,strategydescription,accounttype,publishfrozentime,createtime
login,brokerid,regdate,lastdate,balance,prevmonthbalance,prevbalance,credit,interestrate,equity,margin,margin_level,margin_free,modify_time,gidt,manageraccount
masteraccount,masterbrokerid,followbrokerid,followaccount,startdate,enddate,updatetime
masteraccount,masterbrokerid,followbrokerid,followaccount,startdate,enddate,updatetime
ownerid,objectid,createtime,id
account,brokerid,rateretracementmax,ratioaveragepoints,ratioprofit,ratioedgepoints
Id,accountmobile,ismobileverified,Realname,regplatform,CreateTime
)

start_tm=`date +%s%N`;

num_tables=${#tables[@]}
for (( i=0; i < num_tables; i++ )); do
	name=${tables[i]}
	cols=${colarrs[i]}
	start_tm_tbl=`date +%s%N`;
	hive -e "drop table $prefix$name"
	#hive -e "drop table last_$prefix$name"
        #hive -e "alter table $prefix$name rename to last_$prefix$name"
	#hive -e "drop table $prefix$name"
	#hadoop fs -rm -r -f /user/hadoop/$name
	#hadoop fs -rm -r -f /user/hive/warehouse/$name
	if [ $name = "t_mt4trades" ];then
	sqoop import -D mapred.job.queue.name=root.default --connect "jdbc:sqlserver://10.0.0.34:1433;database=FM_OS_V3" --username fmreader --password EgyksuQ66TxS --table $name --columns \"$cols\" --where "modify_time<'$max_modify_time'" -m 6 --hcatalog-database default --hcatalog-table $prefix$name --create-hcatalog-table --hcatalog-storage-stanza "stored as orcfile"
	#-Dmapred.job.queuename=default
	else
	sqoop import -D mapred.job.queue.name=root.default --connect "jdbc:sqlserver://10.0.0.34:1433;database=FM_OS_V3" --username fmreader --password EgyksuQ66TxS --table $name --columns \"$cols\" -m 6 --hcatalog-database default --hcatalog-table $prefix$name --create-hcatalog-table --hcatalog-storage-stanza "stored as orcfile"
	#-Dmapred.job.queuename=default
	fi
	end_tm_tbl=`date +%s%N`;
	use_tm_tbl=`echo $end_tm_tbl $start_tm_tbl | awk '{ print ($1 - $2) / 1000000000}'`
	echo "table $name time taken:"
	echo $use_tm_tbl
done

hive -e "drop table "$prefix"t_broker"
sqoop import --connect "jdbc:mysql://rr-wz9620lrrhg555x6x.mysql.rds.aliyuncs.com/copytrading" --username liuxiangbin --password m1njooUE04vc --table "$prefix"t_broker --columns "Website,UpdateTime,ShortName,OpenAccountURL,Name,MinLots,IsActive,Introduce,IconURL,FullName,Flag,DepositURL,CreateTime,BrokerID,BigIconURL" -m 6 --hcatalog-database default --hcatalog-table "$prefix"t_broker --create-hcatalog-table --hcatalog-storage-stanza "stored as orcfile"

end_tm=`date +%s%N`;
use_tm=`echo $end_tm $start_tm | awk '{ print ($1 - $2) / 1000000000}'`
echo "in total time taken:"
echo $use_tm
