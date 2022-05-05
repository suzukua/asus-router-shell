

#!/bin/sh

# 更新间隔 分钟
SOCAT_INTERVAL=99

start_socat_5000(){
        if [ -z "$(ps | grep socat | grep TCP6-LISTEN:5000)" ]; then
            nohup socat TCP6-LISTEN:5000,reuseaddr,fork TCP4:192.168.100.4:5000 >/dev/null 2>&1 &
            #write_cron_job
            logger -st "($(basename $0))" $$ "启动成功：socat TCP6-LISTEN:5000,reuseaddr,fork TCP4:192.168.100.4:5000"
        fi
}


write_cron_job(){
    #每x分钟检查一次
    #cru a socat_5000  "*/$SOCAT_INTERVAL * * * * $(readlink -f "$0")"
}

kill_cron_job() {
        if [ -n "$(cru l | grep socat_5000)" ]; then
                logger 删除socat_5000定时更新任务...
                cru d socat_5000
                #sed -i '/f3322/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
        fi
}

case $action in
start)
        logger -st "($(basename $0))" $$ "[socat_5000]: 开始执行socat_5000脚本"
        start_socat_5000
        ;;
*)
        start_socat_5000
        ;;
