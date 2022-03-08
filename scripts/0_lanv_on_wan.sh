#!/bin/sh
#
# 单线复用wan口, 通过vlan的方式延伸lan
#

#LAN延伸到外部的VLAN ID
LAN_VLAN_ID=10

ip link add link eth0 name eth0.$LAN_VLAN_ID type vlan id $LAN_VLAN_ID
ip link set eth0.$LAN_VLAN_ID up
brctl addif br0 eth0.$LAN_VLAN_ID
logger -st "($(basename $0))" $$ "lan已桥接eth0.$LAN_VLAN_ID"

