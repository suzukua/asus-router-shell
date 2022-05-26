#!/bin/sh

# 更新间隔 分钟
INTERVAL=1

start_service() {
        if [ -z "$(ps | grep AdGuardHome | grep -v grep)" ]; then
                nohup /koolshare/adGuardHome/AdGuardHome -w /var/adGuardHome -l syslog -c /koolshare/adGuardHome/AdGuardHome.yaml >/dev/null 2>&1 &
                logger -st "($(basename $0))" $$ "启动成功：AdGuardHome"
        fi
        watch_dog
}


watch_dog() {
        #每x分钟检查一次
        if [ -z "$(cru l | grep AdGuardHome)" ]; then
                cru a adGuardHome  "*/$INTERVAL * * * * $(readlink -f "$0")"
        fi
}

stop_watch_dog() {
        if [ -n "$(cru l | grep adGuardHome)" ]; then
                logger "删除adGuardHome定时更新任务..."
                cru d socat_5001
        fi
}

case $action in
start)
        logger -st "($(basename $0))" $$ "[adGuardHome]: 开始执行adGuardHome脚本"
        start_service
        ;;
*)
        start_service
        ;;
esac
