prefix=$1

tables=(
tsdb-meta
tsdb-tree
tsdb-uid
tsdb
)

file=~/fm/tsdb_hbase2backup.cmd
rm -f $file
touch $file

for i in ${tables[@]}; do
table=$i$prefix
echo "snapshot '$table','snp_${table}'" >> $file 
done

echo 'exist' >> $file

#cat $file
hbase shell -n $file
