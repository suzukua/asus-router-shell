#!/bin/sh

#开启 ad home
# 更新间隔 分钟
INTERVAL=1
AD_DNS_PORT=53535

start_service() {
        if [ -z "$(ps | grep AdGuardHome | grep -v grep)" ]; then
                nohup /koolshare/adGuardHome/AdGuardHome -w /var/adGuardHome -l syslog -c /koolshare/adGuardHome/AdGuardHome.yaml >/dev/null 2>&1 &
                logger -st "($(basename $0))" $$ "启动成功：AdGuardHome"
        fi
        check_conf
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
        if [ ! -f "/jffs/configs/dnsmasq.d/dnsmasq.conf.adh" ]; then
                echo "port=0\ndhcp-option=lan,6,192.168.100.1" > /jffs/configs/dnsmasq.d/dnsmasq.conf.adh
                service restart_dnsmasq
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
