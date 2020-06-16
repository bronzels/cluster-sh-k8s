#####说明：
    在md和sh文件中搜索“！！！手工”是必须手工操作内容，sh有手工操作内容不能直接执行，要一句一句copy执行
    目前只有setup没有remove统一脚本，但是每个单项setup脚本内有kubectl delete -f，逆序执行即可写在相应k8s组件。

#####1，新加入集群的每台机器，要求统一操作系统/内核版本，预装Ubuntu 18.04.3，内核4.15.0。

#####2，每台新加入集群机器，设置用户/口令，设置sshd，每台服务器root用户下，单独执行manual_each.sh

#####3，新建集群，在1台同时用作操作平面的和k8s master01的服务器上，设置ansible环境，执行ansible/ansible_cp.sh
    以下操作无特殊说明都在操作台master01服务器上ubuntu用户下执行

#####4，新建集群
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
    给集群安装k8s dashboard，，执行k8s_dash.sh
    如果后续集群软件安装错误无法恢复，停止卸载k8s，删除所有容器，执行k8s_remove.sh

#####5，新建集群后再加入新机器
    执行步骤2
    ！！！手工，修改/etc/hosts加入新机器别名，/etc/ansible/hosts，/etc/ansible-ubuntu，创建新newgrp租，把新机器同时加入到其他组
    安装docker/k8s，执行docker_k8s_new
    给集群设置控制平面以外多master加入集群，群组masterexpcp修改为newgrp，执行k8s_masters.sh
    给集群设置slaves加入集群，群组all/slaves修改为newgrp，执行k8s_slaves.sh

#####6，创建后续资源命名空间，执行namespace.sh
    同时还汇总组件和namepsace的对应关系。

#####7，在default命名空间安装以下安装共享的组件，执行default.sh
    安装prometheus。

#####8，创建后续postgre/kafka/hadoop/kudu等需要卷存储依赖的动态provision，执行ceph.sh

#####9，创建单机版redis的自定义pod/svc，执行redis.sh

#####10，创建用作流处理mysql源数据汇聚缓存的postgre，执行postre.sh
        
#####11，创建给流处理和数仓使用的2套kafka集群
    zookeeper/kafka集群，执行kafka.sh
    执行kafka_confluent.sh
        创建registry/connector image
        启动registry pod/svc
        被airflow ssh后从控制平面调用的connector ns/pod/svc创建和启动脚本。

#####12，创建用作流处理cube数据聚合缓存的codis/pika集群，执行codis.sh
    被airflow ssh后从控制平面调用的codis/pika集群在serv/servyat命名空间删除/创建的脚本。svc包括：
        codis-proxy
        codis-fe(NodePort)

#####13，创建airflow ssh执行b4str/streaming运行脚本的环境
    创建hadoop集群，执行hadoop.sh
    创建包含hadoopclient的image
        运行sshd
        sqoop/spark/kylin/hbase/hive client程序包
        移植被airflow ssh后从控制平面调用的 spark/kylin/hbase/hive client的scripts脚本
    创建包含hadoopclient pod/svc（ssh），执行hadoop_client.sh

#####14，创建用作流处理历史聚合快照保存opentsdb集群，执行tsdb.sh
    创建指向aws hbase集群hbase-site.xml的configMap
    创建tsdb image，包含
        aws hbase集群版本的hbaseclient程序包和HBASE_HOME环境变量
        opentsdb client程序包
    被airflow ssh后从控制平面调用的opentsdb 复制因子为4的pod和svc在serv/servyat命名空间删除/创建的脚本。svc包括
        ssh
        opentsdb

#####15，定制租用aws hbase集群，
    安装ssh服务
    移植被airflow ssh后从控制平面调用的 hbase/tsdb 库创建脚本
    移植被airflow ssh后从控制平面调用的 hbase/tsdb snap/restore/drop scripts脚本

#####16，创建保存数仓数据的kudu集群，执行kudu.sh
    NodePort方式暴露端口供beta metabase对应的presto访问

#####17，创建用作接入各种catalog的presto集群，执行presto.sh
    hadoopclient hive
    mqstr kafka
    mqdw kafka
    kudu

#####18，创建用作新版本发布工作流集群，执行airflow.sh
    修改批/流处理的consul入口
    建立批/流处理的新consul入口
    建立批/流处理的新consul配置，全部用dns.ns的方式代替原来的ip，端口用svc的端口代替
    修改airflow dag脚本的ssh指向
      新增tsdb的ssh conn指向aws hbase集群
      把到hadoop(sqoop/hive/kylin)的ssh conn修改指向hadoopclient
      把到spark的ssh conn修改指向hadoopclient
      新增flink的ssh conn指向hadoopclient
    清理和启动pika的脚本，移植到ssh到控制平面调用restart codis/pika脚本
    重启tsdb的脚本，移植到ssh到控制平面调用restart tsdb集群脚本
