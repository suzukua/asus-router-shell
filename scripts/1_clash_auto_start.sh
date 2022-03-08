#!/bin/sh

#
# shellClash自启动脚本
#

#shellClash安装目录
clashdir=/tmp/mnt/sda1/.asus/clash

profile=/etc/profile

sed -i '/alias clash=*/'d $profile
echo "alias clash=\"$clashdir/clash.sh\"" >> $profile
sed -i '/export clashdir=*/'d $profile
echo "export clashdir=\"$clashdir\"" >> $profile
. /etc/profile
#sleep 10
sh $clashdir/start.sh start
logger -st "($(basename $0))" $$ "clash 启动脚本执行完成"
