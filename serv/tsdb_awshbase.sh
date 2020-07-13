#ubuntu
cd

mkdir ~/hbase
cd ~/hbase

cat << \EOF >> hbase-site.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
/**
 * Copyright 2010 The Apache Software Foundation
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
-->
<configuration>
  <property>
    <name>hbase.cluster.distributed</name>
    <value>true</value>
  </property>

  <property>
    <name>hbase.zookeeper.quorum</name>
    <value>1110.1110.20.191</value>
  </property>

  <property>
    <name>hbase.rootdir</name>
    <value>hdfs://1110.1110.20.191:8020/user/hbase</value>
  </property>

  <property>
    <name>dfs.support.append</name>
    <value>true</value>
  </property>

  <property>
    <name>hbase.rest.port</name>
    <value>8070</value>
  </property>

  <property>
    <name>hbase.coprocessor.region.classes</name>
    <value>org.apache.hadoop.hbase.coprocessor.example.RefreshHFilesEndpoint</value>
  </property>



</configuration>
EOF
#thrift on 1110.1110.20.191:9090

cat << \EOF > zookeeper_quorum
1110.1110.20.191:2181
EOF

cd ~
tar czvf /tmp/aws-hbase.tar.gz hbase/
rm -rf hbase

