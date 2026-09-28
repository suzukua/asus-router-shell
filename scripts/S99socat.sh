#!/bin/sh
# 放到/koolshare/init.d/文件夹，赋予执行权限 chmod +x S99socat.sh  /jffs/scripts/wan-start >> /koolshare/bin/ks-wan-start.sh
# 定时任务
# 1，用于将公网IPV6端口转发到内网
# 2，检查ddns注册是否正常

SOCAT_INTERVAL=10
SOCAT_FORWARDS=dsm:192.168.100.4:5001

get(){
        a="$(echo $(nvram get $1))"
        echo $a
}

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
    logger -st "($(basename $0))" $$ "添加socat_check定时更新任务..."
  fi
}

kill_cron_job() {
  if [ -n "$(cru l | grep socat_check)" ]; then
    cru d socat_check
    logger -st "($(basename $0))" $$ "删除socat_check定时更新任务..."
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

}

check_ddns() {
    asusddns_token_state=$(get asusddns_token_state)
    if [ $asusddns_token_state = "-3" ]; then
        logger -st "($(basename $0))" $$ "ddns状态异常，正在强制更新 $asusddns_token_state"
        service restart_ddns_le
#        /usr/sbin/inadyn --once --force -n
    fi
}

exec_all_job() {
    # 1, socat运行检查
    batch_start_socat
    # 2, ddns注册状态检查
    check_ddns
    # 3, 检查定时任务
    write_cron_job
}

action=$1
case $action in
start)
    logger -st "($(basename $0))" $$ "[socat]: 开始执行socat脚本"
    exec_all_job
    ;;
kill|stop)
    logger -st "($(basename $0))" $$ "[socat]: 开始删除socat脚本定时任务"
    kill_cron_job
    ;;
*)
    batch_start_socat
    exec_all_job
    ;;
esac
