#!/bin/bash

brokerNames=$1
prefix=$2


tables=(
MT4_TRADES
MT4_USERS
)

colarrs=(
ticket,login,symbol,cmd,volume,open_time,close_time,modify_time,open_price,close_price,profit,swaps,commission,comment
login,regdate,balance,equity,margin,group,city
)

#databases=(
#jojo
#)

databases=(${brokerNames//,/ })

start_tm=`date +%s%N`;

num_dbs=${#databases[@]}
for (( j=0; j < num_dbs; j++ )); do
db=${databases[j]}
num_tables=${#tables[@]}
for (( i=0; i < num_tables; i++ )); do
	name=${tables[i]}
	cols=${colarrs[i]}
	start_tm_tbl=`date +%s%N`;
	eval thisname=$prefix"$db"_$name
	#eval thisdb=followquant_"$db"
	eval thisdb=$db
	hive -e "drop table $thisname"
	~/sqoop/bin/sqoop import --connect "jdbc:mysql://10.1.0.19:32771/"$thisdb"?zeroDateTimeBehavior=CONVERT_TO_NULL&serverTimezone=UTC&useSSL=false" --username root --password followme --table $name --columns \"$cols\" -m 6 --hcatalog-database default --hcatalog-table $thisname --create-hcatalog-table --hcatalog-storage-stanza "stored as orcfile"
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
