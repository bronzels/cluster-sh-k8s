#!/bin/bash
source ~/venvs/airflow/bin/activate

nohup python -u ~/venvs/airflow/dags/watchBroker.py > ~/logs/watchBroker.log 2>&1 &
echo "watch broker start!"

