#upload k8sdeploy.tar.gz to deploy01 /tmp
#root
cd ~

tar xzvf /tmp/k8sdeploy.tar.gz

#if there are libraries, either com or 3rd, tared into spark_jars.tar.gz
./deploy_spark_jars.sh

