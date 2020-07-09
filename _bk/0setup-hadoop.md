#####说明：
    在md和sh文件中搜索“！！！手工”是必须手工操作内容，sh有手工操作内容不能直接执行，要一句一句copy执行
    目前只有setup没有remove统一脚本，但是每个单项setup脚本内有kubectl delete -f，逆序执行即可写在相应k8s组件。
    新加入集群的每台机器，要求统一操作系统/内核版本，预装Ubuntu 18.04.3，内核4.15.0。

#####1，本脚本工程涉及机器hostname/ip没有实现参数化，开始后续步骤之前。
    先到ansible/ansible_cp.sh中，获知最近一次全部重新部署的机器hostname/ip
    用新的一套hostname/ip，在本工程内全程替换掉过去已经无效的机器名hostname/ip，
    ！！！尤其是作为k8s cp的master01，1台机器的ip在很多脚本里直接用到，一定要在这一步提前替换掉。
    ！！！项目定制工程中的dag或者其他定制scripts，也需要修改以上2台机器的ip
    如果有超过或者少于上次部署的机器，譬如上次slave只有4台，这次有8台，需要手工增加到相应的脚本中

#####2，每台新加入集群机器
    设置用户/口令，每台服务器root用户下，
        设置sshd，单独执行native/each.sh；
        如果是aws hbase/tsdb集群，只需要设置master，单独执行native/hbasetsdb_master.sh

#####3，新建k8s/cdh两个集群ansible操作环境，
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
    有问题跳过，给集群的master设置开放podreset，创建为各种os挂载时区文件的podreset，执行k8s/k8s_podreset.sh
    给集群设置helm/docker repo，测试新开发dockerfile能正确启动pod/svc，执行k8s/k8s_helm_registry.sh
    给集群安装k8s dashboard，执行k8s/k8s_dash.sh
    不需要可以跳过，为后续安装创建ubuntu ssh baseimage并测试，执行k8s/k8s_sshbaseimg.sh
    如果后续集群软件安装错误无法恢复，执行k8s/k8s_reset.sh

#####！！！以下操作无特殊说明都在操作台master01服务器上ubuntu用户下执行，并在k8s集群上操作
#####5，新建集群后再加入新机器
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

#####6，创建后续资源命名空间，执行namespace.sh
    同时还汇总组件和namepsace的对应关系。

#####7，在default命名空间安装以下安装共享的组件，执行default.sh
    安装prometheus；
    #安装NFS Server Provisioner。

#####8，后续postgre/kafka/hadoop/kudu等需要卷存储依赖的动态provision，
    创建ceph，执行ceph/ceph.sh
    如果ceph异常需要重装，先要卸载其他所有软件，然后
        按照提示，执行ceph/ceph_remove_devices.sh
        按照ceph/ceph.sh中逆序执行kubectl delete -f语句，卸载ceph

#####9，创建单机版redis的自定义pod/svc，执行redis.sh

#####10，创建用作流处理mysql源数据汇聚缓存的postgre，执行postre.sh
    provisioning pvc包括1个128G

#####11，创建给流处理和数仓使用的2套kafka集群
    zookeeper/kafka集群，执行mq/kafka.sh
    执行mq/kafka_confluent.sh
        创建registry/connector image
        启动registry pod/svc
        被airflow ssh后从控制平面调用的connector ns/pod/svc创建和启动脚本。
    provisioning pvc包括2组各3个kafka-server，每个256G

#####12，创建用作流处理cube数据聚合缓存的codis/pika集群，执行serv/codis.sh
    被airflow ssh后从控制平面调用的codis/pika集群在serv/servyat命名空间删除/创建的脚本。执行serv/codis_pika.sh。
    provisioning pvc包括2组各6个（主备）codis-server/pika，每个128G

#####13，创建用作流处理历史聚合快照保存opentsdb集群
    定制租用aws hbase集群，创建hbase/zookeeper环境设置供后续tsdb安装配置使用，执行serv/tsdb_awshbase.sh
    执行serv/tsdb.sh    
        定制修改helm，创建指向aws hbase集群hbase-site.xml的configMap，配置aws zk
        移植被airflow ssh后从控制平面调用的 hbase/tsdb 库创建脚本到从serv/servyat命名空间heml删除/创建。
        移植被airflow调用happybase调用的 hbase/tsdb snap/drop happybase程序到aws

######14，项目定制部分部署（必须在后续步骤之前进行，因为后续步骤组件需要内嵌定制部分的脚本或者程序）
    如果因为mysql同步出错的原因重新跑，并没有任何程序dag修改，master01直接执行~/scripts/myairflow-cp-op.sh restart
    把prjdeploy下的3个脚本copy到项目定制部署工程的shell目录下，com全程替换为项目名，如果有额外的批流程序或者插件，修改加入部署脚本。
    在项目定制工程里，shell目录，执行k8sdeploy-scripts.sh：
        例如：./k8sdeploy-scripts.sh /mnt/u
    把k8sdeploy-scripts.tar.gz，上传到以下server的/tmp目录
    如果是初次部署，执行（后续重复部署跳过这不）
      cd ~
      rm -rf k8sdeploy-scripts
      tar xzvf /tmp/k8sdeploy-scripts.tar.gz
      部署脚本
        cp相关脚本，上传到master01，ubuntu用户下
            ~/k8sdeploy-scripts/cpscripts/deploy-scripts.sh cpscripts
        hadoop相关脚本，上传到slave01，root用户下
            ~/k8sdeploy-scripts/scripts/deploy-scripts.sh scripts
        tsdb/hbase相关脚本，上传到tsdb/hbase集群master，hadoop用户下
            ~/k8sdeploy-scripts/hbscripts/deploy-scripts.sh hbscripts
    如果是后续重复部署
        cp相关脚本，上传到master01，ubuntu用户下
            deploy-scripts.sh cpscripts
        hadoop相关脚本，上传到master01，ubuntu用户下
            deploy-scripts.sh scripts
        tsdb/hbase相关脚本，上传到tsdb/hbase集群master，hadoop用户下
            deploy-scripts.sh hbscripts
    在项目定制工程里，shell目录，执行k8sdeploy.sh：
      如果是后续部署：
        1，可以用marknot2r.sh，把本次部署不涉及的工程改名；
        2，如果批处理或者流处理程序本身修改，依赖库不修改，可以在build之后删除lib目录，或者maven去掉copy-depedency plugin。
      例如：
        ./k8sdeploy.sh ${version_prefix} prod_k8s /mnt/u
      把${version_prefix}-k8sdeploy.tar.gz上传到master01/slave01（root），然后在master01/slave01（root）
      执行deploy.sh ${version_prefix}
      然后如果后续步骤的初始部署已经全部完成，项目定制的重复部署情况下，具体命令参数参考脚本examploe 
        #批处理相关修改，deploy-master01-batch.sh
        批处理相关修改，deploy-slave01-batch.sh
        流处理相关修改，deploy-master01-str.sh（web监控端口每次新创建，从脚本返回内容里查找）
        airflow dag相关修改，deploy-master01-dags.sh
        数仓confluent插件相关修改，deploy-master01-confluent.sh
        presto UDF插件相关修改，deploy-master01-presto.sh

#####15，安装配置hadoop
    部署zookeeper，执行hadoop/zookeeper.sh
    定制hadoop3的image/yaml，执行hadoop/hadoop3.sh
    定制hadoop nodeport svc yaml，执行hadoop/hadoop_svc.sh
    部署hadoop，执行hadoop/hadoop_setup.sh
    部署hive，把hadoop/hive打包上传解压，执行hive/setup.sh
    部署hbase和其他组件包括：
        spark
        kylin
        sqoop
        ，执行hadoop/hbase2allothers.sh
    provisioning pvc包括
        zookeeper, 3个5G
        hdfs namenode, 1个128G
        hdfs datanode, 4个512G
        hive metastore postgre, 1个8G

#####16，presto基于k8s安装，执行presto.sh。

#####17，flink基于k8s安装，把str目录打包解压到$HOME，执行str/setup.sh。

#####18，创建用作新版本发布工作流集群，执行airflow.sh
    provisioning pvc包括postgresql，8G

