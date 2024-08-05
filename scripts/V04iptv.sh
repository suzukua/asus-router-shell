#!/bin/sh
# 启动IPTV 网口, eth0.43
# vlan UP
LAN_VLAN_ID=43
INTERFACE="eth0.$LAN_VLAN_ID"

# Check if the VLAN interface exists
if ! ip link show "$INTERFACE" > /dev/null 2>&1; then
    ip link add link eth0 name "$INTERFACE" type vlan id $LAN_VLAN_ID
    ip link set "$INTERFACE" up
    # set MAC
    ip link set dev "$INTERFACE" address C4:FF:1F:59:B8:0E
else
    echo "Interface $INTERFACE already exists."
fi

# Check if the PID file exists and the process is running
PID_FILE="/var/run/udhcpc_iptv.pid"

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if [ -d "/proc/$PID" ]; then
        echo "udhcpc is running with PID $PID. release ip..."
        kill -SIGUSR2 `cat $PID_FILE `
        echo "udhcpc is running with PID $PID. Stopping it..."
        sleep 1
        kill "$PID"
        # Wait for the process to stop
        sleep 1
        # Remove the PID file
        rm -f "$PID_FILE"
    else
        echo "PID file exists but no running process with PID $PID."
        rm -f "$PID_FILE"
    fi
fi

# Start udhcpc
# 0x3d clientid
udhcpc -b -i eth0.43 -p "$PID_FILE" -s /koolshare/init.d/iptv.script -x hostname:XXXXX -x 0x3d:XXX -V SCITV -A5
