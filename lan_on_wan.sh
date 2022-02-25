#!/bin/sh
#
# 此程序用于用untagged的vlan通过wan延伸lan.wan走tagged vlan(华硕原厂支持,lan-IPTV,在lan端口设置互联网VID),lan走untagged vlan
#

brctl addif br0 eth0

logger "lan已通过br0桥接eth0"
