git clone https://github.com/mumoshu/kube-airflow.git

MYHOME=~/kube-airflow
cp ${MYHOME} ${MYHOME}.bk

cd ${MYHOME}

file=config/airflow.cfg
sed -i 's@smtp_@#smtp_@g' ${file}
sed -i '/#smtp_mail_from = airflow@airflow.local/a\smtp_host = smtp.exmail.qq.com\nsmtp_starttls = False\nsmtp_ssl = True\nsmtp_user = big-data@followme.cn\nsmtp_password = sf323mNoK\nsmtp_port = 465\nsmtp_mail_from = big-data@followme.cn' ${file}

tar xzvf ~/tmp/k8sdeploy.tar.gz

cp ~/k8sdeploy_dir/dags/* dags/
cp ~/k8sdeploy_dir/requirements.txt requirements/dags.txt

kubectl delete -f airflow.all.yaml -n fl

kubectl create -f airflow.all.yaml -n fl
