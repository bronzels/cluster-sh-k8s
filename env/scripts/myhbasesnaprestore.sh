prefix=$1

tables=(
tsdb-meta
tsdb-tree
tsdb-uid
tsdb
)

file=~/fm/tsdb_hbase2restore.cmd
rm -f $file
touch $file

for i in ${tables[@]}; do
table=$i$prefix
echo "disable '$table'" >> $file 
echo "restore_snapshot 'snp_${table}'" >> $file 
echo "enable '$table'" >> $file 
done

echo 'exit(0)' >> $file

#cat $file
hbase shell -n $file
