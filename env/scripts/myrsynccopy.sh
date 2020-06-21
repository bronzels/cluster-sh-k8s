src=$1
dest=$2
swap=tmp-myrsynccopy

rm -rf ${swap}
mkdir ${swap}
ls ${swap}

if [ $# -eq 3 ];
then
OLD_IFS="$IFS"
#设置分隔符
IFS=","
#如下会自动分隔
skipstr=$3
skips=($skipstr)
echo "skips:${skips}"
#恢复原来的分隔符
IFS="$OLD_IFS"
echo {${skipstr}}
echo $skipstr | sed 's/,/\n/g' > exclude.list
#exit 0
rsync -azP --exclude-from="./exclude.list" $src $swap
else
rsync -azP $src $swap
fi

mv $swap/$src $swap/$dest
mv $swap/$dest ./
rm -rf $swap

if [ $# -eq 3 ];
then
for skip in "${skips[@]}";
do
ln -s $PWD/$src/$skip $PWD/$dest/$skip
done
fi
