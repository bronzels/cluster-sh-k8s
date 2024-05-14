#!/usr/bin/env bash
#find . -name pom.xml | xargs grep '<spark.version>'
#find . -name pom.xml | xargs grep '<hadoop.version>'
#find . -name pom.xml | xargs grep '<hbase.version>'

#find . -name pom.xml | xargs sed -i 's@<spark.version>2.4.0<\/spark.version>@<spark.version>2.4.0-cdh6.3.2<\/spark.version>@g'
#find . -name pom.xml | xargs sed -i 's@<hadoop.version>3.0.0</hadoop.version>@<hadoop.version>3.0.0-cdh6.3.2<\/hadoop.version>@g'
#find . -name pom.xml | xargs sed -i 's@<hbase.version>2.1.0</hbase.version>@<hbase.version>2.1.0-cdh6.3.2<\/hbase.version>@g'

#find . -name pom.xml | xargs sed -i 's@<spark.version>2.4.0-cdh6.3.2<\/spark.version>@<spark.version>2.4.0<\/spark.version>@g'
#find . -name pom.xml | xargs sed -i 's@<hadoop.version>3.0.0-cdh6.3.2</hadoop.version>@<hadoop.version>3.0.0<\/hadoop.version>@g'
#find . -name pom.xml | xargs sed -i 's@<hbase.version>2.1.0-cdh6.3.2</hbase.version>@<hbase.version>2.1.0<\/hbase.version>@g'

#find . -name pom.xml | xargs grep 'com.google.guava'

:<<EOF
#example:
./k8sdeploy.sh 2_2_4_0_0 prod_k8s /mnt/u
./k8sdeploy.sh 2_2_4_0_0 prod_k8s /i
EOF


currdir=$PWD

version_prefix=$1
echo "version_prefix:${version_prefix}"
env_name=$2
echo "env_name:${env_name}"
prj_home=$3
echo "prj_home:${prj_home}"

rm -rf k8sdeploy_dir
mkdir k8sdeploy_dir

if [ -d "${prj_home}"/comdeploy ]; then
  echo "------in comdeploy"
  mkdir -p ./k8sdeploy_dir/py
  cp -rv "${prj_home}"/comdeploy/py ./k8sdeploy_dir
  rm -rf ./k8sdeploy_dir/py/com/dags
  rm -rf ./k8sdeploy_dir/py/pycomtrade
  rm -rf ./k8sdeploy_dir/py/test
  rm -rf ./k8sdeploy_dir/py/func
  rm -rf ./k8sdeploy_dir/py/pycomtrade/spark
  mkdir -p ./k8sdeploy_dir/py/com/dags
  cp -rv "${prj_home}"/comdeploy/py/com/dags/"${env_name}"/kylin_str/* ./k8sdeploy_dir/py/com/dags
  cp -rv "${prj_home}"/comdeploy/py/com/dags/datawarehouse/k8s/* ./k8sdeploy_dir/py/com/dags
  cp "${prj_home}"/comdeploy/py/com/dags/"${env_name}"/com_config_env.py ./k8sdeploy_dir/py/com/config/

  mkdir ./k8sdeploy_dir/dags
  cp -rv ./k8sdeploy_dir/py/com/dags/* ./k8sdeploy_dir/dags
  cp -rv ./k8sdeploy_dir/py  ./k8sdeploy_dir/dags
  rm -rf ./k8sdeploy_dir/py

fi

if [ -d "${prj_home}"/comstreaming ]; then
  echo "------in comstreaming"
  mkdir ./k8sdeploy_dir/str_jar
  cp -v "${prj_home}"/comstreaming/target/comstreaming-1.0-SNAPSHOT.jar ./k8sdeploy_dir/str_jar

  if [ -d ${prj_home}/comstreaming/target/lib ]; then
    cd ${prj_home}/comstreaming/target/lib/
    tar czvf ${currdir}/k8sdeploy_dir/flink_com_libfiles.tar.gz *.jar
    cd ${currdir}
  fi
fi

if [ -d "${prj_home}"/spark-loaded2dw -o -d "${prj_home}"/comb4str ]; then
  echo "------in batch prepare"
  mkdir ./k8sdeploy_dir/batch_jar
  if [ -d "${prj_home}"/spark-loaded2dw/target/lib -o -d "${prj_home}"/comb4str/target/lib ]; then
    mkdir ./k8sdeploy_dir/spark_shared_jars
  fi
fi
if [ -d "${prj_home}"/spark-loaded2dw ]; then
  echo "------in spark-loaded2dw"
  cp -v "${prj_home}"/spark-loaded2dw/target/spark-loaded2dw-1.0-SNAPSHOT.jar ./k8sdeploy_dir/batch_jar
  if [ -d ${prj_home}/spark-loaded2dw/target/lib ]; then
    cp -v ${prj_home}/spark-loaded2dw/target/lib/* ./k8sdeploy_dir/spark_shared_jars/
  fi
fi
if [ -d "${prj_home}"/comb4str ]; then
  echo "------in comb4str"
  cp -v "${prj_home}"/comb4str/target/comb4str-1.0-SNAPSHOT.jar ./k8sdeploy_dir/batch_jar
  if [ -d ${prj_home}/comb4str/target/lib ]; then
    cp -v ${prj_home}/comb4str/target/lib/* ./k8sdeploy_dir/spark_shared_jars/
  fi
fi
if [ -d "${prj_home}"/spark-loaded2dw -o -d "${prj_home}"/comb4str ]; then
  echo "------in batch tar"
  if [ -d ${prj_home}/spark-loaded2dw/target/lib -o -d ${prj_home}/comb4str/target/lib ]; then
    cd ./k8sdeploy_dir/spark_shared_jars/
    tar czvf ../spark_shared_jars.tar.gz *.jar
    cd ${currdir}
    rm -rf k8sdeploy_dir/spark_shared_jars/
  fi
fi

if [ -d "${prj_home}"/kafka-connect-contrib ]; then
  echo "------in kafka-connect-contrib"
  mkdir k8sdeploy_dir/kafka-connect-contrib
  cp -v ${prj_home}/kafka-connect-contrib/target/kafka-connect-contrib-1.3.1-SNAPSHOT.jar k8sdeploy_dir/kafka-connect-contrib/
  if [ -d ${prj_home}/kafka-connect-contrib/target/lib ]; then
    cp -v ${prj_home}/kafka-connect-contrib/target/lib/* k8sdeploy_dir/kafka-connect-contrib/
  fi
fi

if [ -d "${prj_home}"/comkcplugin ]; then
  echo "------in comkcplugin"
  mkdir k8sdeploy_dir/comkcplug
  cp -v ${prj_home}/comkcplugin/target/comkcplugin-0.0.1-SNAPSHOT.jar k8sdeploy_dir/comkcplug/
  if [ -d ${prj_home}/comkcplugin/target/lib ]; then
    cp -v ${prj_home}/comkcplugin/target/lib/* k8sdeploy_dir/comkcplug/
  fi
fi

if [ -d "${prj_home}"/complugin ]; then
  echo "------in complugin"
  mkdir k8sdeploy_dir/comprplg
  cp -v ${prj_home}/complugin/target/comprestoplugin-1.0-SNAPSHOT.jar k8sdeploy_dir/comprplg/
  if [ -d ${prj_home}/complugin/target/lib ]; then
    cp -v ${prj_home}/complugin/target/lib/* k8sdeploy_dir/comprplg/
  fi
fi

cp "${prj_home}"/comdeploy/shell/requirements.txt k8sdeploy_dir/dags/

tar -czvf ${version_prefix}-k8sdeploy.tar.gz k8sdeploy_dir
