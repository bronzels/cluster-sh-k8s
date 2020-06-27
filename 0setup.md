#####说明：
    在md和sh文件中搜索“！！！手工”是必须手工操作内容，sh有手工操作内容不能直接执行，要一句一句copy执行
    目前只有setup没有remove统一脚本，但是每个单项setup脚本内有kubectl delete -f，逆序执行即可写在相应k8s组件。

#####1，新加入集群的每台机器，要求统一操作系统/内核版本，预装Ubuntu 18.04.3，内核4.15.0。

#####2，每台新加入集群机器
    设置用户/口令，每台服务器root用户下，
        设置sshd，单独执行manual/each.sh；
        如果是cdh集群的slaves，分区格式化和挂载数据盘，单独执行manual/slaves.sh；
        如果是aws hbase/tsdb集群，只需要设置master，单独执行manual/hbasetsdb_master.sh

#####3，新建k8s/cdh两个集群ansible操作环境，
    在同时用作操作平面的slave01的服务器上，设置ansible环境，执行
        ansible/ansible_cp.sh
        ansible/ansible_slave01.sh
    在同时用作操作平面的和k8s master01的服务器上，设置ansible环境，执行
        ansible/ansible_cp.sh
        ansible/ansible_master01.sh

#####4，新建k8s集群
    给集群安装docker，执行docker.sh
    给集群安装k8s，执行k8s/k8s.sh，
    masters/slaves加入集群：    
        或者，全新安装，把k8s.sh的kubeadm init之后如下提示后的kubeadam join，生成的key：
            You can now join any number of control-plane nodes by copying certificate authorities
                         and service account keys on each node and then running the following as root:
        或者，长时间以后有新masters/slaves新加入集群，执行k8s.sh的kubeadm token create新的key：
        copy到k8s/k8s_masters，k8s//k8s_slaves脚本。
            给集群设置控制平面以外多master加入集群，执行k8s/k8s_masters.sh
            给集群设置slaves加入集群，执行k8s/k8s_slaves.sh
    给集群设置helm/docker repo，测试新开发dockerfile能正确启动pod/svc，执行k8s/k8s_helm_registry.sh
    给集群安装k8s dashboard，，执行k8s/k8s_dash.sh
    如果后续集群软件安装错误无法恢复，执行k8s/k8s_reset.sh

#####5，安装配置cdh环境
    ！！！一定要装好k8s以后再安装cdh，因为cdh依赖docker启动mysql，但是k8s网络安装期间docker会退出甚至严重会无法再启动
    安装和配置cdh环境，在slave01环境先后执行native/
      slaves，格式化和挂载cdh数据盘
      cdh/cdh_common_bf.sh
      cdh/cdh-6.3.2.sh
      cdh/cdh_common_af.sh
    在cloudera web配置页面，参考cdh_web_manual.sh做额外手工设置
    测试集群，执行cdh_test.sh
    如果安装发生错误，执行native/cdh_remove.sh
    安装kylin，执行kylin.sh

#####！！！以下操作无特殊说明都在操作台master01服务器上ubuntu用户下执行，并在k8s集群上操作
#####6，新建集群后再加入新机器
    执行步骤2
    ！！！手工，在新机器上执行manual_each.sh
    ！！！手工，master01/slave01上执行ansible_cp部分内容。
        修改/etc/hosts加入新机器别名；
        修改/etc/ansible/hosts，/etc/ansible-ubuntu，加入新机器别名；
        创建新newgrp租；
        执行ssh scan/add_keys；
    ！！！手工，master01上把新hosts copy到所有机器。
    安装docker/k8s，执行docker_k8s_new.sh
    给集群设置控制平面以外多master加入集群，执行k8s_masters.sh：
        群组masterk8sexpcp修改为newgrp；
        kubecacp-cert-masters.sh的vohost包括新加机器；
    给集群设置slaves加入集群，群组slavesk8s修改为newgrp，执行k8s_slaves.sh

#####7，创建后续资源命名空间，执行namespace.sh
    同时还汇总组件和namepsace的对应关系。

#####8，在default命名空间安装以下安装共享的组件，执行default.sh
    安装prometheus；
    安装NFS Server Provisioner。

#####9，创建后续postgre/kafka/hadoop/kudu等需要卷存储依赖的动态provision，执行ceph.sh

#####10，创建单机版redis的自定义pod/svc，执行redis.sh

#####11，创建用作流处理mysql源数据汇聚缓存的postgre，执行postre.sh
    provisioning pvc包括1个128G

#####12，创建给流处理和数仓使用的2套kafka集群
    zookeeper/kafka集群，执行mq/kafka.sh
    执行mq/kafka_confluent.sh
        创建registry/connector image
        启动registry pod/svc
        被airflow ssh后从控制平面调用的connector ns/pod/svc创建和启动脚本。
    provisioning pvc包括2组各3个kafka-server，每个256G

#####13，创建用作流处理cube数据聚合缓存的codis/pika集群，执行serv/codis.sh
    被airflow ssh后从控制平面调用的codis/pika集群在serv/servyat命名空间删除/创建的脚本。执行serv/codis_pika.sh。
    svc包括：
        codis-proxy
        codis-fe(NodePort)
    provisioning pvc包括2组各6个（主备）codis-server/pika，每个128G

#####14，presto基于k8s安装，执行presto.sh。

#####15，flink基于k8s安装，执行flink.sh。

#####16，创建用作流处理历史聚合快照保存opentsdb集群
    定制租用aws hbase集群，创建hbase/zookeeper环境设置供后续tsdb安装配置使用，执行serv/tsdb_awshbase.sh
    执行serv/tsdb.sh    
        定制修改helm，创建指向aws hbase集群hbase-site.xml的configMap，配置aws zk
        移植被airflow ssh后从控制平面调用的 hbase/tsdb 库创建脚本到从serv/servyat命名空间heml删除/创建。
        移植被airflow调用happybase调用的 hbase/tsdb snap/drop happybase程序到aws

#####17，创建用作新版本发布工作流集群，执行airflow.sh
    修改批/流处理的consul入口
    建立批/流处理的新consul入口
    建立批/流处理的新consul配置，全部用dns.ns的方式代替原来的ip，端口用svc的端口代替
    修改airflow dag脚本的ssh指向
      新增tsdb的ssh conn指向aws hbase集群
      把到hadoop(sqoop/hive/kylin)的ssh conn修改指向cdh master
      把到spark的ssh conn修改指向cdh master
      flink
        cancel任务的http指向新的session svc
        启动/停止flink的命令移植成ssh到cp来helm install/uninstall flink集群
    清理和启动pika的脚本，移植到ssh到控制平面调用restart codis/pika脚本
    重启tsdb的脚本，移植到ssh到控制平面调用restart tsdb集群脚本

######18，新版本发布之前，k8s环境准备，执行/env/cpscripts/（或master01 ~/scripts/)
    在项目定制工程里，shell目录，执行k8sdeploy.sh，准备k8sdeploy.tar.gz，上传到master01
      cd ~
      tar xzvf /tmp/k8sdeploy.tar.gz
      然后
        批处理相关修改，deploy_master01_batch.sh
        流处理相关修改，deploy_master01_str.sh
        airflow dag相关修改，deploy_master01_dags.sh
        数仓confluent插件相关修改，deploy_master01_confluent.sh
        presto UDF插件相关修改，deploy_master01_presto.sh
    在项目定制工程里，shell目录，执行k8sdeploy-scripts.sh，准备k8sdeploy-scripts.tar.gz
      cp相关脚本，上传到master01，ubuntu用户下
        cd ${HOME}
        tar xzvf /tmp/k8sdeploy-scripts.tar.gz
        cp ${HOME}/k8sdeploy-scripts/cpscripts/* ${HOME}/scripts
      hadoop相关脚本，上传到slave01，root用户下
        cd ${HOME}
        tar xzvf /tmp/k8sdeploy-scripts.tar.gz
        cp ${HOME}/k8sdeploy-scripts/scripts/* ${HOME}/scripts
      tsdb/hbase相关脚本，上传到tsdb/hbase集群master，hadoop用户下
        cd ${HOME}
        tar xzvf /tmp/k8sdeploy-scripts.tar.gz
        cp ${HOME}/k8sdeploy-scripts/hbscripts/* ${HOME}/scripts
