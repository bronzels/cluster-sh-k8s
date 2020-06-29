git clone https://github.com/mumoshu/kube-airflow.git

MYHOME=${HOME}/kube-airflow
cp -rf ${MYHOME} ${MYHOME}.bk

cd ~
cp -rf ${MYHOME}.bk ${MYHOME}
cd ${MYHOME}

file=config/airflow.cfg
cp ${MYHOME}.bk/${file} ${file}
sed -i 's@smtp_@#smtp_@g' ${file}
sed -i '/#smtp_mail_from = airflow@airflow.local/a\smtp_host = smtp.exmail.qq.com\nsmtp_starttls = False\nsmtp_ssl = True\nsmtp_user = big-data@followme.cn\nsmtp_password = sf323mNoK\nsmtp_port = 465\nsmtp_mail_from = big-data@followme.cn' ${file}
sed -i 's@load_examples = {{ LOAD_DAGS_EXAMPLES }}@load_examples = False@g' ${file}

find ~/kube-airflow -name "*.yaml"  | xargs grep "apiVersion: apps/v1beta1"
find ~/kube-airflow -name "*.yaml" | xargs sed -i 's@apiVersion: apps/v1beta1@apiVersion: apps/v1@g'

find ~/kube-airflow -name "*.yaml"  | xargs grep "apiVersion: extensions/v1beta1"
sed -i 's@apiVersion: extensions/v1beta1@apiVersion: apps/v1@g' airflow.all.yaml
sed -i '/^  name: postgres/{
:a
N
/\nspec:/!ba
a\
  selector:\n      matchLabels:\n        app: airflow\n        tier: db
}
' airflow.all.yaml
sed -i '/^  name: rabbitmq/{
:a
N
/\nspec:/!ba
a\
  selector:\n      matchLabels:\n        app: airflow\n        tier: rabbitmq
}
' airflow.all.yaml
sed -i '/^  name: web/{
:a
N
/\nspec:/!ba
a\
  selector:\n      matchLabels:\n        app: airflow\n        tier: web
}
' airflow.all.yaml
sed -i '/^  name: flower/{
:a
N
/\nspec:/!ba
a\
  selector:\n      matchLabels:\n        app: airflow\n        tier: flower
}
' airflow.all.yaml
sed -i '/^  name: scheduler/{
:a
N
/\nspec:/!ba
a\
  selector:\n      matchLabels:\n        app: airflow\n        tier: scheduler
}
' airflow.all.yaml
sed -i '/^  name: worker/{
:a
N
/\nspec:/!ba
a\
  selector:\n      matchLabels:\n        app: airflow\n        tier: worker
}
' airflow.all.yaml
sed -i 's@apiVersion: extensions/v1beta1@apiVersion: apps/v1@g'  airflow/templates/deployments-web.yaml
sed -i '/^  name: {{ template \"airflow.fullname\" . }}-web/{
:a
N
/\nspec:/!ba
a\
  selector:\n      matchLabels:\n        app: {{ template \"airflow.name\" . }}-web\n        release: {{ .Release.Name }}
}
' airflow/templates/deployments-web.yaml
sed -i 's@apiVersion: extensions/v1beta1@apiVersion: apps/v1@g'  airflow/templates/deployments-flower.yaml
sed -i '/^  name: {{ template \"airflow.fullname\" . }}-flower/{
:a
N
/\nspec:/!ba
a\
  selector:\n      matchLabels:\n        app: {{ template \"airflow.name\" . }}-flower\n        release: {{ .Release.Name }}
}
' airflow/templates/deployments-flower.yaml
sed -i 's@apiVersion: extensions/v1beta1@apiVersion: apps/v1@g'  airflow/templates/deployments-scheduler.yaml
sed -i '/^  name: {{ template \"airflow.fullname\" . }}-scheduler/{
:a
N
/\nspec:/!ba
a\
  selector:\n      matchLabels:\n        app: {{ template \"airflow.name\" . }}-scheduler\n        release: {{ .Release.Name }}
}
' airflow/templates/deployments-scheduler.yaml

find ~/kube-airflow -name "*.yaml"  | xargs grep "apiVersion: extensions/v1beta1"

:<<EOF
        \&\&  apt-get remove openssl  -yqq \\\
        \&\&  apt-get install wget  -yqq \\\
        \&\&  wget https:\/\/www.openssl.org\/source\/openssl-1.1.1a.tar.gz \\\
        \&\&  tar -zxvf openssl-1.1.1a.tar.gz \\\
        \&\&  cd openssl-1.1.1a \\\
        \&\&  .\/config --prefix=\/usr\/local\/openssl no-zlib \\\
        \&\&  make \\\
        \&\&  make install \\\
        \&\&  ln -s \/usr\/local\/openssl\/include\/openssl \/usr\/include\/openssl \\\
        \&\&  mkdir \/usr\/local\/lib64\/ \\\
        \&\&  ln -s \/usr\/local\/openssl\/lib\/libssl.so.1.1 \/usr\/local\/lib64\/libssl.so \\\
        \&\&  rm -f \/usr\/bin\/openssl \\\
        \&\&  ln -s \/usr\/local\/openssl\/bin\/openssl \/usr\/bin\/openssl \\\
        \&\&  cd .. \\\

        \&\&  .\/configure --prefix=\/usr\/local\/python36  --with-openssl=/usr/local/openssl --enable-shared --enable-loadable-sqlite-extensions  \\\
EOF


file=Makefile
cp ${MYHOME}.bk/${file} ${file}
sed -i '/mkdir -p $(BUILD_ROOT)/a\\tcp -rf ~\/.pip $(BUILD_ROOT)' ${file}

file=Dockerfile.template
cp ${MYHOME}.bk/${file} ${file}
sed -i 's@pip3 install@python3 -m pip install@g' ${file}
sed -i '/RUN         set -ex/i\
RUN     apt-get update -yqq \\\
        \&\&  apt-get install software-properties-common -yqq \\\
        \&\&  add-apt-repository ppa:jonathonf\/python-3.6 \\\
        \&\&  apt-get update -yqq \\\
        \&\&  apt-get install python3.6  -yqq' ${file}


sed -i '/python3-dev \\/d' ${file}
sed -i '/python3-pip \\/d' ${file}
sed -i '/build-essential \\/d' ${file}
sed -i '/apt-get update -yqq \\/d' ${file}
mysetuppkg=setuptools-27.3.0
mypipkg=pip-8.1.2
myvenvpkg=virtualenv-15.1.0
sed -i '/RUN         set -ex/i\
COPY     .pip ${HOME}/.pip' ${file}
sed -i '/RUN         set -ex/i\
RUN     apt-get update -yqq \\\
        \&\&  apt-get install wget  -yqq \\\
        \&\&  apt-get install build-essential -yqq \\\
        \&\&  apt-get install zlib1g.dev bzip2 libncurses5 libreadline-dev sqlite libgdbm-dev libdb-dev python-dev libbz2-dev  -yqq \\\
        \&\&  wget https:\/\/www.python.org\/ftp\/python\/PYTHONREV\/Python-PYTHONREV.tgz \\\
        \&\&  tar -xzvf Python-PYTHONREV.tgz \\\
        \&\&  cd Python-PYTHONREV\/   \\\
        \&\&  .\/configure --prefix=\/usr\/local\/python36  --with-openssl --enable-shared --enable-loadable-sqlite-extensions  \\\
        \&\&  make -j8 && make install    \\\
        \&\&  chmod 777 -R \/usr\/local\/python36 \\\
        \&\&  ln -sf \/usr\/local\/python36\/bin\/python \/usr\/bin\/python3' ${file}
sed -i 's@PYTHONREV@3.6.7@g' ${file}
sed -i '/RUN         set -ex/i\
RUN     wget https://pypi.python.org/packages/72/e1/741cd8c4825e58119481d8be4254c9cd133db50876b159cdf8cbd253fbb3/setuptools-27.3.0.tar.gz#md5=2246eb4c511fa4b50003b10ea2a49d42 \\\
        \&\&  tar xzvf mysetuppkg.tar.gz \\\
        \&\&  cd mysetuppkg \&\& python setup.py install \\\
        \&\&  wget https://pypi.python.org/packages/e7/a8/7556133689add8d1a54c0b14aeff0acb03c64707ce100ecd53934da1aa13/pip-8.1.2.tar.gz#md5=87083c0b9867963b29f7aba3613e8f4a \\\
        \&\&  tar xzvf mypipkg.tar.gz \\\
        \&\&  ls \\\
        \&\&  cd mypipkg \&\& python setup.py install \\\
        \&\&  wget https://pypi.python.org/packages/d4/0c/9840c08189e030873387a73b90ada981885010dd9aea134d6de30cd24cb8/virtualenv-15.1.0.tar.gz#md5=44e19f4134906fe2d75124427dc9b716 \\\
        \&\&  tar xzvf myvenvpkg.tar.gz \\\
        \&\&  cd myvenvpkg \&\& python setup.py install \\\
        \&\&  ln -s \/usr\/local\/python36\/bin\/pip3 \/usr\/bin\/pip3' ${file}
sed -i '/RUN         set -ex/i\ENV PATH /usr/local/python36/bin:$PATH' ${file}
sed -i '/RUN         set -ex/i\ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:\/usr\/local\/python36\/lib' ${file}
sed -i 's@mysetuppkg@setuptools-27.3.0@g' ${file}
sed -i 's@mypipkg@pip-8.1.2@g' ${file}
sed -i 's@myvenvpkg@virtualenv-15.1.0@g' ${file}

file=script/entrypoint.sh
cp ${MYHOME}.bk/${file} ${file}
sed -i '/$CMD \"$@\"/i\
python3 -V; \\\
whereis python; \\\
echo $PATH; \\\
export PATH=\/usr\/local\/python36\/bin:$PATH:$AIRFLOW_HOME; \\\
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:\/usr\/local\/python36\/lib
' ${file}

#kubectl create -f airflow.all.yaml -n fl
:<<EOF
mkdir deploy
cp -rf ~/k8sdeploy_dir/dags mydeploy/
cp -rf ~/k8sdeploy_dir/requirements.txt mydeploy/
export ENBEDDED_DAGS_LOCATION=mydeploy/dags
export REQUIREMENTS_TXT_LOCATION=mydeploy/requirements.txt
EOF
rm -rf dags
cp -rf ${MYHOME}.bk/dags ./
cp -rf ~/k8sdeploy_dir/dags/* dags/
rm -rf requirements
cp -rf ${MYHOME}.bk/requirements ./
cp ~/k8sdeploy_dir/requirements.txt requirements/dags.txt

docker images|grep "<none>"|awk '{print $3}'|xargs docker rmi -f
make build

:<<EOF
kubectl delete -f airflow.all.yaml -n fl

kubectl get pod -n fl
kubectl get svc -n fl

kubectl exec -n fl -t `kubectl get pod -n fl | grep web | awk '{print $1}'`  -- ls /usr/local/airflow
kubectl exec -n fl -t `kubectl get pod -n fl | grep web | awk '{print $1}'`  -- python -V
EOF
