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
. $clashdir/start.sh start
