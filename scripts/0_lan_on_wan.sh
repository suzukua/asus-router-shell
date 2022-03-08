#!/bin/sh
#
# 单线复用wan口。wan走vlan(华硕原厂支持,lan-IPTV,在lan端口设置互联网VID),lan走untagged vlan
# eth0 默认的wan
#

if [[ -z "$( brctl show | grep -o eth0 | sed -n 1p )" ]];
then
  brctl addif br0 eth0
  logger -st "($(basename $0))" $$ "lan通过br0桥接eth0成功"
else
  logger -st "($(basename $0))" $$ "eth0已桥接至br0,跳过执行本脚本"
fi
