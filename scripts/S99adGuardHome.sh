#!/bin/sh

#开启 ad home
# 更新间隔 分钟
INTERVAL=1
AD_DNS_PORT=53535
WORK_HOME="/tmp/adGuardHome"
start_service() {
        check_conf
        if [ -z "$(ps | grep AdGuardHome | grep -v grep)" ]; then
                if [ ! -d $WORK_HOME ]; then
                        mkdir $WORK_HOME
                fi
                nohup /koolshare/adGuardHome/AdGuardHome -w $WORK_HOME -l syslog -c /koolshare/adGuardHome/AdGuardHome.yaml >/dev/null 2>&1 &
                sleep 2s
                if [ ! -z "$(pidof AdGuardHome)" -a ! -z "$(netstat -anp | grep AdGuardHome)" ] ; then
                    LOGGER "AdGuardHome 进程启动成功！(PID: $(pidof AdGuardHome))"
                else
                    LOGGER "AdGuardHome 进程启动失败！请检查配置"
                    stop 
                fi
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

check_conf() {
        #禁用dnsmasq的dns功能,让adh监听到53端口接管dns，dhcp-option=lan,6下发ipv4的dns
#         dhcp-option=lan,6,192.168.1.1
#         dhcp-option=lan,option6:23,[::]
        if [ ! -f "/jffs/configs/dnsmasq.d/dnsmasq.conf.adh" ]; then
                echo -e "port=5533\ndhcp-option=lan,6,192.168.100.1" > /jffs/configs/dnsmasq.d/dnsmasq.conf.adh
                service restart_dnsmasq
        fi

}

stop() {
        if [ -f "/jffs/configs/dnsmasq.d/dnsmasq.conf.adh" ]; then
                rm -rf/jffs/configs/dnsmasq.d/dnsmasq.conf.adh >/dev/null 2>&1 &
                service restart_dnsmasq
        fi
        if [ -n "$(cru l | grep adGuardHome)" ]; then
                logger "删除adGuardHome定时更新任务..."
                cru d adGuardHome
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
