prefix=$1

file=~/fm/tsdb_hbase2dropkylin.cmd
rm -f $file
touch $file

echo "disable_all 'KYLIN.*'" >> $file 
echo "drop_all 'KYLIN.*'" >> $file 

echo 'exit' >> $file

#cat $file
hbase shell -n $file
