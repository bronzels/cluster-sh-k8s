#!/bin/bash
echo "!!!Remove name/value pair between <property></property>..."
echo file:$1
echo name:$2

#echo "s/<name>$2.*<\/value>/xxx/g"
#sed "s/<name>$2.*<\/value>/xxx/g" $1

declare -i name_lno
declare -i value_lno
sedstring=""

name_lno=`grep -n "$2" $1 | head -1 | cut -d ":" -f 1`
echo $name_lno
if [ $name_lno -ne 0 ];then
  let  "value_lno=$name_lno+1" 
  sedstring="${name_lno},${value_lno}d"
  echo $sedstring 
  sed -i "$sedstring" $1
  time=`date`" by "`whoami`
  sed -i "${name_lno} i\<!-- property $2 is removed by removename.sh ${time}-->" $1
else
  echo "!!!name is not found..."
fi