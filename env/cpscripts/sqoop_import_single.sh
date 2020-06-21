#!/bin/bash
#spark-sql -f /app/hadoop/fm_sql_test/sqoop.sql

start_tm=`date +%s%N`;

#num_tables=${#tables[@]}
#for (( i=0; i < num_tables; i++ )); do
	#name=${tables[i]}
	name=$1
	#cols=${colarrs[i]}
	cols=$2
	start_tm_tbl=`date +%s%N`;
	hive -e "drop table $name"
	#hadoop fs -rm -r -f /user/hadoop/$name
	#hadoop fs -rm -r -f /user/hive/warehouse/$name
	sqoop import --connect "jdbc:sqlserver://119.23.168.162:52435;database=FM_OS_V3" --username fmreader --password EgyksuQ66TxS --table $name --columns \"$cols\" -m 6 --hcatalog-database default --hcatalog-table $name --create-hcatalog-table --hcatalog-storage-stanza "stored as orcfile"
	end_tm_tbl=`date +%s%N`;
	use_tm_tbl=`echo $end_tm_tbl $start_tm_tbl | awk '{ print ($1 - $2) / 1000000000}'`
	echo "table $name time taken:"
	echo $use_tm_tbl
#done

end_tm=`date +%s%N`;
use_tm=`echo $end_tm $start_tm | awk '{ print ($1 - $2) / 1000000000}'`
echo "in total time taken:"
echo $use_tm
