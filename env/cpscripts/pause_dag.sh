dagid=$1
. /app/hadoop/.bash_profile;. /app/hadoop/venvs/airflow/bin/activate;airflow pause $dagid
