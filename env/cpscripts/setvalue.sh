#!/bin/bash
echo "!!!Set or insert name/value pair between <property></property>..."
echo file:$1
echo name:$2
echo value:$3

declare -i name_lno
declare -i val_lno

name_lno=`grep -n "$2" $1 | head -1 | cut -d ":" -f 1`
echo $name_lno
time=`date`" by "`whoami`
if [ $name_lno -eq 0 ];then

sed -i "/<\/configuration>/i\
<!-- added by setvalue.sh ${time}-->\n\
    <property>\n\
      <name>$2<\/name>\n\
      <value>$3<\/value>\n\
    <\/property>\n\
<!-- end added ${time}-->\n\
" $1

else

let  "val_lno=$name_lno+1" 
echo $val_lno

value_l=`awk -v l=$val_lno 'NR==l{print}' $1`
echo $value_l

echo "${val_lno}s@\(<value>)[^/]*<\/value>@\1/$3@"
#sed -i "${val_lno}s/\<value\>\<\/value\>/$3/g" $1
#sed "${val_lno}s@\(<value>\)[^/]*</value>@\1$3@" $1
sed -i "${val_lno}s/\(<value>\).*\(<\/value>\)/\1$3\2/" $1
sed -i "${val_lno} a\<!-- end set value ${time}-->" $1
sed -i "${name_lno} i\<!-- value set by setvalue.sh ${time}-->" $1

fi