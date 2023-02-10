#!/bin/sh
# 开启后重启一次WiFi，解决AX86U部分物联网设备连接WiFi无法上网(无法获取IP)的问题
# 重启UPNP，解决UPNP不稳定问题

logger -st "($(basename $0))" $$ "开始执行重启WiFi"
i=0
while [ $i -le 20 ]; do
      success_start_service=`nvram get success_start_service`
      if [ "$success_start_service" == "1" ]; then
              break
      fi
      i=$(($i+1))
      logger -st "($(basename $0))" $$ "当前WiFi未启动: 等待 $i seconds..."
      sleep 1
done
logger -st "($(basename $0))" $$ "关闭WiFi并等待5秒..."
radio off
sleep 5
logger -st "($(basename $0))" $$ "开启WiFi..."
radio on
service restart_wireless
logger -st "($(basename $0))" $$ "重启WiFi完毕"

logger -st "($(basename $0))" $$ "开始重启UPNP..."
service restart_upnp
logger -st "($(basename $0))" $$ "重启UPNP完毕"
