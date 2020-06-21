src=$1
dest=$2
swap=swap`date --date='0 days ago' "+%Y-%m-%d_%H_%M_%S"`

mkdir ${swap}

if [ $# -eq 3 ];
then
OLD_IFS="$IFS"
#设置分隔符
IFS=","
#如下会自动分隔
skipstr=$3
skips=($skipstr)
echo "libs:${libs}"
#恢复原来的分隔符
IFS="$OLD_IFS"
rsync -azP --exclude={${skipstr}} $src $swap
else
rsync -azP $src $swap
fi

mv $swap/$src $dest
rm -rf $swap

if [ $# -eq 3 ];
then
for skip in "${skips[@]}";
do
ln -s $src/$skip $dest/$skip
done
fi
