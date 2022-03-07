#!/bin/sh
#
# 单线复用wan口, 通过vlan的方式延伸lan
#

#LAN延伸到外部的VLAN ID
LAN_VLAN_ID=10


# vconfig add "eth0" "$LAN_VLAN_ID"
# brctl addif "br0" "vlan$LAN_VLAN_ID"
# ifconfig "vlan$LAN_VLAN_ID" up


ip link add link eth0 name eth0.$LAN_VLAN_ID type vlan id $LAN_VLAN_ID
ip link set eth0.$LAN_VLAN_ID up
brctl addif br0 eth0.$LAN_VLAN_ID

logger "lan已桥接eth0.$LAN_VLAN_ID"

