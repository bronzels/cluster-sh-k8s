db=$1
lag=$2
sleepsec=$3

table_arr=(
mg_result_all
mg_result_brsymday
mg_result_day
mg_result_follall
mg_result_follday
mg_result_hour
mg_result_month
mg_result_order
mg_result_symall
mg_result_symday
mg_result_symmonth
mg_result_symweekofyear
mg_result_week
mg_result_weekofyear
)

while [ 1 ]
do
differ_total=0
for table in "${table_arr[@]}";
do
    master_count=`~/scripts/mymongodb_eval.sh $db "print(db.${table}.count())"`
    slave_count=`~/scripts/mymongodbslave_eval.sh $db "print(db.${table}.count())"`
    let differ=master_count-slave_count
    echo "table:"$table", master_count:"$master_count", slave_count:"$slave_count", differ:"$differ
    let differ_total=differ_total+differ
done

echo "differ_total:"$differ_total

if [ $differ_total -lt $lag ] ;then
   echo "catch up successfully, congratulations"
   break
fi

sleep $sleepsec

done

