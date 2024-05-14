#!/usr/bin/env bash

:<<EOF
#example:
./marknot2r.sh comstreaming,comb4str,spark-loaded2dw,kafka-connect-contrib,comkcplugin,complugin /mnt/u
./marknot2r.sh comstreaming,comb4str,spark-loaded2dw,kafka-connect-contrib,comkcplugin,complugin /mnt/u undo
./marknot2r.sh comstreaming,comb4str,spark-loaded2dw,kafka-connect-contrib,comkcplugin,complugin /i
./marknot2r.sh comstreaming,comb4str,spark-loaded2dw,kafka-connect-contrib,comkcplugin,complugin /i undo
EOF

OLD_IFS="$IFS"
#设置分隔符
IFS=","
#如下会自动分隔
libs=($1)
echo "libs:${libs}"
#恢复原来的分隔符
IFS="$OLD_IFS"

prj_home=$2
echo "prj_home:${prj_home}"

for name in "${libs[@]}";
do
  echo "name:${name}"
  path=${prj_home}/${name}
  echo "path:${path}"
  if [ $# -eq 3 ]; then
    if [ $3 == "undo" ]; then
      mv ${path}.not2r ${path}
    fi
  else
    mv ${path} ${path}.not2r
  fi
done
