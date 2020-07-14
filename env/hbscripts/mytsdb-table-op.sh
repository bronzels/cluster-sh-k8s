#!/bin/bash
# Small script to setup the HBase tables used by OpenTSDB.
set -x

op=$1
echo "op:${op}"
table_prefix=$2
echo "table_prefix:${table_prefix}"

:<<EOF
test -n "$HBASE_HOME" || {
  echo >&2 'The environment variable HBASE_HOME must be set'
  exit 1
}
test -d "$HBASE_HOME" || {
  echo >&2 "No such directory: HBASE_HOME=$HBASE_HOME"
  exit 1
}
EOF

TSDB_TABLE=${TSDB_TABLE-"tsdb${table_prefix}"}
UID_TABLE=${UID_TABLE-"tsdb-uid${table_prefix}"}
TREE_TABLE=${TREE_TABLE-"tsdb-tree${table_prefix}"}
META_TABLE=${META_TABLE-"tsdb-meta${table_prefix}"}
BLOOMFILTER=${BLOOMFILTER-'ROW'}
# LZO requires lzo2 64bit to be installed + the hadoop-gpl-compression jar.
#COMPRESSION=${COMPRESSION-'LZO'}
COMPRESSION=NONE
# All compression codec names are upper case (NONE, LZO, SNAPPY, etc).
COMPRESSION=`echo "$COMPRESSION" | tr a-z A-Z`
# DIFF encoding is very useful for OpenTSDB's case that many small KVs and common prefix.
# This can save a lot of storage space.
DATA_BLOCK_ENCODING=${DATA_BLOCK_ENCODING-'DIFF'}
DATA_BLOCK_ENCODING=`echo "$DATA_BLOCK_ENCODING" | tr a-z A-Z`
TSDB_TTL=${TSDB_TTL-'FOREVER'}

case $COMPRESSION in
  (NONE|LZO|GZIP|SNAPPY)  :;;  # Known good.
  (*)
    echo >&2 "warning: compression codec '$COMPRESSION' might not be supported."
    ;;
esac

case $DATA_BLOCK_ENCODING in
  (NONE|PREFIX|DIFF|FAST_DIFF|ROW_INDEX_V1)  :;; # Know good
  (*)
    echo >&2 "warning: encoding '$DATA_BLOCK_ENCODING' might not be supported."
    ;;
esac

# HBase scripts also use a variable named `HBASE_HOME', and having this
# variable in the environment with a value somewhat different from what
# they expect can confuse them in some cases.  So rename the variable.
if [ $op == "drop" -o $op == "recreate" ]; then
exec hbase shell <<EOF
disable '$UID_TABLE'
drop '$UID_TABLE'

disable '$TSDB_TABLE'
drop '$TSDB_TABLE'

disable '$TREE_TABLE'
drop '$TREE_TABLE'

disable '$META_TABLE'
drop '$META_TABLE'
EOF

if [ $op == "drop" ]; then
exit 0
fi
fi

if [ $op == "snap" ]; then
exec hbase shell <<EOF
disable '$UID_TABLE'
restore_snapshot 'snp_$UID_TABLE'
enable '$UID_TABLE'

disable '$TSDB_TABLE'
restore_snapshot 'snp_$TSDB_TABLE'
enable '$TSDB_TABLE'

disable '$TREE_TABLE'
restore_snapshot 'snp_$TREE_TABLE'
enable '$TREE_TABLE'

disable '$META_TABLE'
restore_snapshot 'snp_$META_TABLE'
enable '$META_TABLE'
EOF

exit 0
fi

if [ $op == "restore" ]; then
exec hbase shell <<EOF
restore_snapshot 'snp_$UID_TABLE'
restore_snapshot 'snp_$TSDB_TABLE'
restore_snapshot 'snp_$TREE_TABLE'
restore_snapshot 'snp_$META_TABLE'
EOF

exit 0
fi

if [ $op == "create" -o $op == "recreate" ]; then
exec hbase shell <<EOF
create '$UID_TABLE',
{NAME => 'id', COMPRESSION => '$COMPRESSION', BLOOMFILTER => '$BLOOMFILTER', DATA_BLOCK_ENCODING => '$DATA_BLOCK_ENCODING'},
{NAME => 'name', COMPRESSION => '$COMPRESSION', BLOOMFILTER => '$BLOOMFILTER', DATA_BLOCK_ENCODING => '$DATA_BLOCK_ENCODING'}, SPLITS => ['\x00\xea\x60','\x01\xd4\xc0','\x02\xbf\x20','\x03\xa9\x80']

create '$TSDB_TABLE',
  {NAME => 't', VERSIONS => 1, COMPRESSION => '$COMPRESSION', BLOOMFILTER => '$BLOOMFILTER', DATA_BLOCK_ENCODING => '$DATA_BLOCK_ENCODING', TTL => '$TSDB_TTL'}, SPLITS => ['\x00\x5b\x25','\x01\x11\x6f','\x01\xc7\xb9','\x02\x7e\x03','\x03\x34\x4d','\x03\x8f\x72','\x04\x45\xbc','\x04\xa0\xe1','\x05\x57\x2b','\x05\xb2\x50','\x06\x0d\x75','\x06\xc3\xbf','\x07\x1e\xe4','\x07\x7a\x09','\x07\xd5\x2e','\x08\x30\x53','\x08\xe6\x9d','\x09\x41\xc2','\x09\xf8\x0c','\x0A\xC5s\xEFZ\xBBL','\x0C\x17\x10\xD5\x5Cp','\x0Di\x91\xD6Z\xF4_','\x0E\xB0\xC0\x0F]\xFA\xDA','\x10\x01Z*[\xBBG','\x11T\x0E-Z\xCE','\x12\xA8\xD2VX\xCB','x0aS1']

create '$TREE_TABLE',
{NAME => 't', VERSIONS => 1, COMPRESSION => '$COMPRESSION', BLOOMFILTER => '$BLOOMFILTER', DATA_BLOCK_ENCODING => '$DATA_BLOCK_ENCODING'}

create '$META_TABLE',
{NAME => 'name', COMPRESSION => '$COMPRESSION', BLOOMFILTER => '$BLOOMFILTER', DATA_BLOCK_ENCODING => '$DATA_BLOCK_ENCODING'}
EOF
fi