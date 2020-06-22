#!/bin/bash
prefix=$1
lvd_prefix=$2
#is_fl=$3
is_fl=' '
echo prefix:"${prefix}" lvd_prefix:${lvd_prefix}
flink_run="flink run -d -e kubernetes-session -Dkubernetes.cluster-id=myflink "
flink_run_class="-c com.fm.data.fmstreaming.FMMain /app/hadoop/fm/str/fmstreaming-1.0-SNAPSHOT.jar "

echo ${flink_run}

task_cli_input_arr=(
"${flink_run} -p 3 ${flink_run_class} -p fm  -t all -tc trcl -tr second -fmopsmplstatic -pf source=-3 -c ${prefix} -lc ${lvd_prefix} ${is_fl} "
"${flink_run} -p 1 ${flink_run_class} -p fm  -t week -fmopsmplstatic -c ${prefix} -lc ${lvd_prefix} ${is_fl} "
"${flink_run} -p 1 ${flink_run_class} -p fm  -t order,brsymday -fmopsmplstatic -c ${prefix} -lc ${lvd_prefix} ${is_fl} "
"${flink_run} -p 1 ${flink_run_class} -p fm  -t weekofyear,month  -tc trcl,inout,tr1st -fmopsmplstatic -c ${prefix} -lc ${lvd_prefix} ${is_fl} "
"${flink_run} -p 1 ${flink_run_class} -p fm  -t symall -fmopsmplstatic -c ${prefix}  -lc ${lvd_prefix} ${is_fl} "
"${flink_run} -p 1 ${flink_run_class} -p fm  -t day -tc trcl,inout -fmopsmplstatic -c ${prefix}  -lc ${lvd_prefix} ${is_fl} "
"${flink_run} -p 1 ${flink_run_class} -p fm  -t hour -fmopsmplstatic -c ${prefix}  -lc ${lvd_prefix} ${is_fl} "
"${flink_run} -p 1 ${flink_run_class} -p fm  -t all -tc tr1st,tu,acc,inout -fmopsmplstatic  -c ${prefix} -lc ${lvd_prefix} ${is_fl} "
"${flink_run} -p 1 ${flink_run_class} -p fm  -t symmonth,symweekofyear,symday -fmopsmplstatic -c ${prefix} -lc ${lvd_prefix} ${is_fl} "
"${flink_run} -p 1 ${flink_run_class} -p fm  -t all,day,month -fmopsmplstatic -tc trcl_lvd -lc ${lvd_prefix} ${is_fl} "
"${flink_run} -p 3 ${flink_run_class} -p fm  -t all -tc tr,trop -pf source=-3 -c  ${prefix} ${is_fl} "
"${flink_run} -p 3 ${flink_run_class} -p fm  -t follall,follday,follweekofyear -fmopsmplstatic -pf source=-3 -tc trcl_lvd -lc ${lvd_prefix} ${is_fl} "
"${flink_run} -p 1 ${flink_run_class} -p fm  -t all,day,month,follall,follday,follweekofyear -tc tr_lvd -lc ${lvd_prefix} ${is_fl} "
)

num_task=${#task_cli_input_arr[@]}
for (( i=0; i < num_task; i++ )); do
	task_cli_input=${task_cli_input_arr[i]}
	  ${task_cli_input}
done


