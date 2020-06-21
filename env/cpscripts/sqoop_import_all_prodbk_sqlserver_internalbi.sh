#!/bin/bash
#spark-sql -f /app/hadoop/fm_sql_test/sqoop.sql

prefix=$1

tables1=(
follower_user_info
customer
fm_user
)
colarrs1=(
)
server1=jdbc:mysql://rm-wz9h0x9e6z9l376pr.mysql.rds.aliyuncs.com:3306/crm
user1=liuxiangbin
passwd1=m1njooUE04vc
tables2=(
T_Users
T_Trades
)
colarrs2=(
)
server2=jdbc:mysql://rm-wz905j9253s6l04l6.mysql.rds.aliyuncs.com:3306/copytrading
user2=liuxiangbin
passwd2=m1njooUE04vc
start_tm=`date +%s%N`;

for (( j=1; j < 3; j++ )); do
_num_tables=#tables$j[@]
eval num_tables=\${$_num_tables}
echo $num_tables
eval server=\$server$j
echo $server
eval user=\$user$j
eval passwd=\$passwd$j
for (( i=0; i < num_tables; i++ )); do
        eval name=\${tables$j[i]}
	echo $name
        #eval cols=\${colarrs$j[i]}
        start_tm_tbl=`date +%s%N`;
        #hive -e "drop table $prefix$name"
        hive -e "drop table last_$prefix$name"
        hive -e "alter table $prefix$name rename to last_$prefix$name"
        #hive -e "drop table $prefix$name"
        #hadoop fs -rm -r -f /user/hadoop/$name
        #hadoop fs -rm -r -f /user/hive/warehouse/$name        
	#--columns \"$cols\"
	sqoop import --connect \"$server\" --username $user --password $passwd --table $name -m 6 --hcatalog-database default --hcatalog-table $prefix$name --create-hcatalog-table --hcatalog-storage-stanza "stored as orcfile"
        end_tm_tbl=`date +%s%N`;
        use_tm_tbl=`echo $end_tm_tbl $start_tm_tbl | awk '{ print ($1 - $2) / 1000000000}'`
        echo "table $name time taken:"
        echo $use_tm_tbl
done
done

end_tm=`date +%s%N`;
use_tm=`echo $end_tm $start_tm | awk '{ print ($1 - $2) / 1000000000}'`
echo "in total time taken:"
echo $use_tm
