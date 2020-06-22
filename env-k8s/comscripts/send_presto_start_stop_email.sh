#!/bin/bash
flag=$1

notification_email()
{
    emailuser='big-data@followme.cn'
    emailpasswd='sf323mNoK'
    emailsmtp='smtp.exmail.qq.com'
#    sendto='937880309@qq.com,jiangshaodong@followme.cn'
    sendto='caokaiming@followme.cn,liuzhiyuan@followme.cn,liangrongmin@followme.cn,duwenkang@followme.cn,chenguilin@followme.cn,liwenyong@followme.cn,wenxiaojun@followme.cn,wangweinan@followme.cn'
    title="metabase presto $flag"
    /app/hadoop/sendEmail-v1.56/sendEmail -f $emailuser -t $sendto -s $emailsmtp -u $title -xu $emailuser -xp $emailpasswd
}

email_body="metabase presto status: $flag"

if [ "$flag" = "stop" ];then
   echo -e $email_body | notification_email
fi
	
if [ "$flag" = "start" ];then
   echo -e $email_body | notification_email
fi
