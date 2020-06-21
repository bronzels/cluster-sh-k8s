prefix=$1

tables=(
tsdb-meta
tsdb-tree
tsdb-uid
tsdb
)

file=~/fm/tsdb_hbase2drop.cmd
rm -f $file
touch $file

for i in ${tables[@]}; do
table=$i$prefix
echo "disable '$table'" >> $file 
echo "drop '$table'" >> $file 
done

echo 'exit' >> $file

#cat $file
hbase shell -n $file
