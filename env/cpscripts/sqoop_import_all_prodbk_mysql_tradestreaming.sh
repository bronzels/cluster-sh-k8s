#!/bin/bash
#spark-sql -f /app/hadoop/fm_sql_test/sqoop.sql

#jdbc:mysql://rm-wz905j9253s6l04l6.mysql.rds.aliyuncs.com:3306/mt4_pico
#liuxiangbin
#m1njooUE04vc

prefix=$1

tables=(
t_followorder
t_users
t_activefollow
t_follow
t_trades
)

colarrs=(
ID,TraderAccount,TraderBrokerID,TraderTradeID,Account,BrokerID,TradeID,Status,ClosedAt
ID,Account,BrokerID,Balance,Credit,Equity,Margin,MarginLevel,MarginFree,UpdateTime
ID,TraderAccount,TraderBrokerID,BrokerID,Account,StartTime,EndTime
ID,TraderAccount,TraderBrokerID,BrokerID,Account,StartTime,EndTime
ID,TradeID,Account,BrokerID,Symbol,Cmd,OpenTime,CloseTime,UpdateTime,OpenPrice,ClosePrice,Profit,Swaps,Commission,StandardSymbol,StandardLots,Pips
)

tables_acc=(
user_accounts
users
)

colarrs_acc=(
id,mt4_account,broker_id,account_status,user_type,user_id,account_index,strategy_description,account_type,publish_frozen_time
id,mobile,is_mobile_verified,realname,register_platform,create_time
)

start_tm=`date +%s%N`;

num_tables=${#tables[@]}
for (( i=0; i < num_tables; i++ )); do
	name=${tables[i]}
	cols=${colarrs[i]}
	start_tm_tbl=`date +%s%N`;
        hive -e "drop table $prefix$name"
	sqoop import --connect "jdbc:mysql://rm-wz905j9253s6l04l6.mysql.rds.aliyuncs.com:3306/copytrading" --username liuxiangbin --password m1njooUE04vc --table $name --columns \"$cols\" -m 6 --hcatalog-database default --hcatalog-table $prefix$name --create-hcatalog-table --hcatalog-storage-stanza "stored as orcfile"
	end_tm_tbl=`date +%s%N`;
	use_tm_tbl=`echo $end_tm_tbl $start_tm_tbl | awk '{ print ($1 - $2) / 1000000000}'`
	echo "table $name time taken:"
	echo $use_tm_tbl
done

num_tables_acc=${#tables_acc[@]}
for (( i=0; i < num_tables_acc; i++ )); do
	name=${tables_acc[i]}
	cols=${colarrs_acc[i]}
	start_tm_tbl=`date +%s%N`;
        hive -e "drop table $prefix$name"
	sqoop import --connect "jdbc:mysql://rm-wz905j9253s6l04l6.mysql.rds.aliyuncs.com:3306/account" --username liuxiangbin --password m1njooUE04vc --table $name --columns \"$cols\" -m 6 --hcatalog-database default --hcatalog-table $prefix$name --create-hcatalog-table --hcatalog-storage-stanza "stored as orcfile"
	end_tm_tbl=`date +%s%N`;
	use_tm_tbl=`echo $end_tm_tbl $start_tm_tbl | awk '{ print ($1 - $2) / 1000000000}'`
	echo "table $name time taken:"
	echo $use_tm_tbl
done

sqoop import --connect "jdbc:sqlserver://10.0.0.34:1433;database=FM_OS_V3" --username fmreader --password EgyksuQ66TxS --table s_follower --columns "ownerid,objectid,createtime,id" -m 6 --hcatalog-database default --hcatalog-table "$prefix"s_follower --create-hcatalog-table --hcatalog-storage-stanza "stored as orcfile"

end_tm=`date +%s%N`;
use_tm=`echo $end_tm $start_tm | awk '{ print ($1 - $2) / 1000000000}'`
echo "in total time taken:"
echo $use_tm

