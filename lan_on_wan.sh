#!/bin/sh
#
# 此程序用于用untagged的vlan通过wan延伸lan.wan走tagged vlan(华硕原厂支持,lan-IPTV,在lan端口设置互联网VID),lan走untagged vlan
#

ifconfig eth0 down
brctl addif br0 eth0
ifconfig eth0 up
