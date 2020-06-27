#如果是项目定制开发的dag部分有修改
#把k8sdeploy.sh打包生成k8sdeploy.tar.gz上传到master01，解压到home目录

cd ~/kube-airflow

cp ~/k8sdeploy_dir/dags/* dags/
cp ~/k8sdeploy_dir/requirements.txt requirements/dags.txt

kubectl delete -f airflow.all.yaml -n fl
kubectl create -f airflow.all.yaml -n fl
