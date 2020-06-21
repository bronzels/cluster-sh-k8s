#!/bin/bash
p="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
prefix=$1
tables=(
HOUR
DAY
WEEK
MONTH
ALL
SYMDAY
SYMMONTH
SYMALL
FOLLDAY
FOLLALL
)

start_tm=`date +%s%N`;

num_tables=${#tables[@]}
for (( i=0; i < num_tables; i++ )); do
	name=${tables[i]}
	idx="IDX_"
	file=$PWD/$prefix$name.sql
	idxfile=$PWD/$idx$prefix$name.sql
	echo $file
	start_tm_tbl=`date +%s%N`;
	$p/phoenix_create.sh $file
	$p/phoenix_create.sh $idxfile
	end_tm_tbl=`date +%s%N`;
	use_tm_tbl=`echo $end_tm_tbl $start_tm_tbl | awk '{ print ($1 - $2) / 1000000000}'`
	echo "table $name time taken:"
	echo $use_tm_tbl
done

end_tm=`date +%s%N`;
use_tm=`echo $end_tm $start_tm | awk '{ print ($1 - $2) / 1000000000}'`
echo "in total time taken:"
echo $use_tm
