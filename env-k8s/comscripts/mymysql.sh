#!/bin/bash
myenv=$1
db=$2
echo "myenv:$myenv"
echo "db:$db"
if [ $myenv == "beta" ]; then
	mysql -h 10.1.0.7 -P 3326 -ufmbetadb002 -p31Bawd0c5GEq -D$db
else
	mysql -h ??? -P 3306 -uliuxiangbin -pm1njooUE04vc -D$db
fi
