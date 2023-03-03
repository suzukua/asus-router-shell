#!/bin/sh
# 放到/koolshare/init.d/文件夹，赋予执行权限 chmod +x S99socat.sh  /jffs/scripts/wan-start >> /koolshare/bin/ks-wan-start.sh
# 更新间隔 分钟
# 重启UPNP，解决UPNP不稳定问题
SOCAT_INTERVAL=10
SOCAT_FORWARDS=dsm:192.168.100.4:5001,emby:192.168.100.6:8096

start_socat() {
  name=$1
  ip=$2
  port=$3
  echo $name $ip $port
  if [ -z "$(ps | grep socat | grep TCP6-LISTEN:$port | grep -v grep)" ]; then
    nohup socat TCP6-LISTEN:$port,reuseaddr,fork TCP4:$ip:$port >/dev/null 2>&1 &
    logger -st "($(basename $0))" $$ "启动成功 $name：socat TCP6-LISTEN:$port,reuseaddr,fork TCP4:$ip:$port"
  fi
  open_port_ip6tables "$port"
}

open_port_ip6tables() {
  port=$1
  #开放端口
  if [ -z "$(ip6tables -L -n |grep $port)" ]; then
    ip6tables -I INPUT -p tcp --dport $port -j ACCEPT
    logger -st "($(basename $0))" $$ "ip6tables添加成功：ip6tables -I INPUT -p tcp --dport $port -j ACCEPT"
  fi
}

write_cron_job() {
  #每x分钟检查一次
  if [ -z "$(cru l | grep socat_check)" ]; then
    cru a socat_check  "*/$SOCAT_INTERVAL * * * * $(readlink -f "$0")"
  fi
}

kill_cron_job() {
  if [ -n "$(cru l | grep socat_check)" ]; then
    logger "删除socat_check定时更新任务..."
    cru d socat_check
  fi
}

check_restart_upnp() {
  upnppid=$(pidof miniupnpd)
  echo "upnppid进程号${upnppid}"
  #进程号小于10000，重启upnp
  if [ -z "$upnppid" ] || [ $upnppid -lt 10000 ]; then
    logger -st "($(basename $0))" $$ "原upnpn pid: ${upnppid}，开始重启UPNP..."
    service restart_upnp
    logger -st "($(basename $0))" $$ "重启UPNP完毕"
  fi
}


batch_start_socat() {
  for item in $(echo ${SOCAT_FORWARDS} | awk '{split($0,arr,",");for(i in arr) print arr[i]}')
  do
    i=0
    for it in $(echo ${item} | awk '{slen=split($0,arr,":");for(i=1;i<=slen;i++) print arr[i]}')
    do
      if [ "$i" -eq "0" ]
      then
        name=$it
      fi
      if [ "$i" -eq "1" ]
      then
        ip=$it
      fi
      if [ "$i" -eq "2" ]
      then
        port=$it
      fi
      i=`expr $i + 1`
    done
    start_socat "$name" "$ip" "$port"
  done
#   check_restart_upnp
  write_cron_job
}

case $action in
start)
        logger -st "($(basename $0))" $$ "[socat_dsm]: 开始执行socat_dsm脚本"
        batch_start_socat
        ;;
*)
        batch_start_socat
        ;;
esac
