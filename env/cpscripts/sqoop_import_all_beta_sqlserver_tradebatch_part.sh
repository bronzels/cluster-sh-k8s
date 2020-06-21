#!/bin/bash
#spark-sql -f /app/hadoop/fm_sql_test/sqoop.sql

prefix=$1

tables=(
t_traderscore
)
colarrs=(
account,brokerid,rateretracementmax,ratioaveragepoints,ratioprofit,ratioedgepoints
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
	~/sqoop/bin/sqoop import --connect "jdbc:sqlserver://10.1.0.3:1433;database=FM_OS_V3" --username betadb001 --password fXpcD6hxL7Vj --table $name --columns \"$cols\" -m 6 --hcatalog-database default --hcatalog-table $prefix$name --create-hcatalog-table --hcatalog-storage-stanza "stored as orcfile"
	end_tm_tbl=`date +%s%N`;
	use_tm_tbl=`echo $end_tm_tbl $start_tm_tbl | awk '{ print ($1 - $2) / 1000000000}'`
	echo "table $name time taken:"
	echo $use_tm_tbl
done

end_tm=`date +%s%N`;
use_tm=`echo $end_tm $start_tm | awk '{ print ($1 - $2) / 1000000000}'`
echo "in total time taken:"
echo $use_tm
