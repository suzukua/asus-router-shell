#!/bin/sh

# 更新间隔 分钟
SOCAT_INTERVAL=10

start_socat_5001() {
        if [ -z "$(ps | grep socat | grep TCP6-LISTEN:5001)" ]; then
                nohup socat TCP6-LISTEN:5001,reuseaddr,fork TCP4:192.168.100.4:5001 >/dev/null 2>&1 &
                logger -st "($(basename $0))" $$ "启动成功：socat TCP6-LISTEN:5001,reuseaddr,fork TCP4:192.168.100.4:5001"
        fi
        if [ -z "$(ip6tables -L -n |grep 5001)" ]; then
                ip6tables -I INPUT -p tcp --dport 5001 -j ACCEPT
                logger -st "($(basename $0))" $$ "ip6tables添加成功：ip6tables -I INPUT -p tcp --dport 5001 -j ACCEPT"
        fi
        write_cron_job
}


write_cron_job(){
        #每x分钟检查一次
        if [ -z "$(cru l | grep socat_5001)" ]; then
                cru a socat_5001  "*/$SOCAT_INTERVAL * * * * $(readlink -f "$0")"
        fi
}

kill_cron_job() {
        if [ -n "$(cru l | grep socat_5001)" ]; then
                logger "删除socat_5001定时更新任务..."
                cru d socat_5001
        fi
}

case $action in
start)
        logger -st "($(basename $0))" $$ "[socat_5001]: 开始执行socat_5001脚本"
        start_socat_5001
        ;;
*)
        start_socat_5001
        ;;
esac
