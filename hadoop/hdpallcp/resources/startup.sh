set -x

~/scripts/cp_funcs.sh

HADOOP_CONFIG_DIR="/tmp/hadoop-config"
for f in slaves core-site.xml hdfs-site.xml mapred-site.xml yarn-site.xml; do
    "${HADOOP_CONFIG_DIR}/$f"
    realf=
    if [[ -e  ]]; then
    cp ${HADOOP_CONFIG_DIR}/$f $HADOOP_HOME/etc/hadoop/$f
    else
    echo "ERROR: Could not find $f in $HADOOP_CONFIG_DIR"
    exit 1
    fi
done

HIVE_CONFIG_DIR="/tmp/hive-config"
# Copy config files from volume mount
for f in hive-site.xml; do
    if [[ -e ${HIVE_CONFIG_DIR}/$f ]]; then
    cp ${HIVE_CONFIG_DIR}/$f $HIVE_HOME/conf/$f
    else
    echo "ERROR: Could not find $f in $HIVE_CONFIG_DIR"
    exit 1
    fi
done

HBASE_CONFIG_DIR="/tmp/hbase-config"
# Copy config files from volume mount
for f in hbase-site.xml; do
    if [[ -e ${HBASE_CONFIG_DIR}/$f ]]; then
    cp ${HBASE_CONFIG_DIR}/$f $HBASE_HOME/conf/$f
    else
    echo "ERROR: Could not find $f in $HBASE_CONFIG_DIR"
    exit 1
    fi
done
