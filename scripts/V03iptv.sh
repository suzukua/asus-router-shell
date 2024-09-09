#!/bin/sh
# 启动IPTV 网口, eth0.43
# 放置于任何目录都可以, 建议放到 /koolshare/init.d/ 目录下.开机自动运行, 网络变化自适应.

# vlan UP
LAN_VLAN_ID=43
INTERFACE="eth0.$LAN_VLAN_ID"

# Check if the PID file exists and the process is running
PID_FILE="/var/run/udhcpc_iptv.pid"

#LOCK
LOCK_FILE=/var/lock/iptv.lock

set_lock() {
  exec 2000>"$LOCK_FILE"
  flock -x 2000
}

unset_lock() {
  flock -u 2000
  rm -rf "$LOCK_FILE"
}

add_system_event_sh() {
  current_file=$(pwd)/$(basename "$0")
  [ ! -e "/koolshare/init.d/V03iptv.sh" ] && ln -sf $current_file /koolshare/init.d/V03iptv.sh
  [ ! -e "/koolshare/init.d/N03iptv.sh" ] && ln -sf $current_file /koolshare/init.d/N03iptv.sh
}

add_interface() {
  # Check if the VLAN interface exists
  if ! ip link show "$INTERFACE" > /dev/null 2>&1; then
      ip link add link eth0 name "$INTERFACE" type vlan id $LAN_VLAN_ID
      ip link set "$INTERFACE" up
      # set MAC
      ip link set dev "$INTERFACE" address 01:00:00:00:00:00
  else
      logger -st "($(basename $0))" $$ "Interface $INTERFACE already exists."
  fi
}

start_dhcp() {
  if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if [ -d "/proc/$PID" ]; then
        logger -st "($(basename $0))" $$ "udhcpc is running with PID $PID. release ip..."
        kill -SIGUSR2 `cat $PID_FILE `
        logger -st "($(basename $0))" $$ "udhcpc is running with PID $PID. Stopping it..."
        sleep 1
        kill "$PID"
        # Wait for the process to stop
        sleep 1
        # Remove the PID file
        rm -f "$PID_FILE"
    else
        logger -st "($(basename $0))" $$ "PID file exists but no running process with PID $PID."
        rm -f "$PID_FILE"
    fi
  fi
  # Start udhcpc
  # 0x3d clientid
  udhcpc -b --syslog -i eth0.43 -p "$PID_FILE" -s /koolshare/init.d/iptv.script -x hostname:XXXXX -x 0x3d:XXX -V SCITV -A5
}

# 1,加锁, 防止并发
set_lock
# 2,设置IPTV网口
add_interface
# 3,启动DHCP获取IP
start_dhcp
# 4,添加开机启动，以及系统事件监听脚本
add_system_event_sh
# 4, 程序结束释放锁
unset_lock
