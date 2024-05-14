#!/bin/bash

days=7
day_01=`date -d "-${days} day" +%Y-%m-%d`
#running_array=(`yarn application -list | grep application_1 | awk '{print  $1}' > running.log `)
#running_array=(`more running.log`)

running_array=(`yarn application -list | grep application_1 | awk '{print  $1}' `)
len=${#running_array[*]}
len=$(($len-1))

echo $len

running_string=""
for ((i=0; i< ${#running_array[*]}; i++))
do
echo "----${running_array[$i]}'\|' "
if [ $i -lt $len ];then
	running_string+=${running_array[$i]}"\|"
	echo "less n-1 : $len ====="
else
	running_string+=${running_array[$i]}
	echo "== n-1 :${#running_array[*]} "
fi
done


running_string='application_1543891127613_1125'
echo $running_string

#history_logs_to_delete=(`hdfs dfs -ls /user/spark/applicationHistory/ | grep application_ | grep -v $running_string | awk ' {print $8}' `)
#history_logs_to_delete=(`more spark.log | grep application_ | grep -v $running_string | awk ' {print $8}' `)

#history_logs_to_delete=(`hdfs dfs -ls /tmp/logs/hdfs/logs/ | grep application_ | grep -v $running_string | awk '{if( $6 lt $day_01) print $8 } ' `)

echo $day_01

history_logs_to_delete=(`hdfs dfs -ls /tmp/logs/hadoop/logs/ | grep application_ | awk '{if( $6 lt $day_01) print $8 } ' `)
echo $history_logs_to_delete
for ((j=0; j< ${#history_logs_to_delete[*]}; j++))
do
history_logs_str=${history_logs_to_delete[$j]}
echo $history_logs_str
echo " `date +%F\ %T` to delete $j ==$history_logs_str " >> history_logs_to_delete.log
hdfs dfs -rm -r $history_logs_str
done

history_logs_to_delete=(`hdfs dfs -ls /apprunning/ | grep application_ | awk '{if( $6 lt $day_01) print $8 } ' `)
echo $history_logs_to_delete
for ((j=0; j< ${#history_logs_to_delete[*]}; j++))
do
history_logs_str=${history_logs_to_delete[$j]}
echo $history_logs_str
echo " `date +%F\ %T` to delete $j ==$history_logs_str " >> history_logs_to_delete.log
hdfs dfs -rm -r $history_logs_str
done

