
#!/bin/sh

# F3322账号信息
F3322_HOST=""
F3322_USER=""
F3322_PASSWORD=""

# 更新间隔 分钟
F3322_INTERVAL=99

start_f3322(){
        rm -rf /tmp/f3322.txt
        wan_ip=$(nvram get wan0_ipaddr)
        service="http://$F3322_USER:$F3322_PASSWORD@members.3322.org/dyndns/update?hostname=$f3322_hostname&$wan_ip"
        wget -q -O - $service > /tmp/f3322.txt
        if [ $? -eq 0 ]; then
                        if [ -z "$(cat /tmp/f3322.txt)" ]; then
                                logger "[F3322]内容为空，请检查账号密码服务器是否准确"
                                exit 1
                        else
                                ftag=$(cat /tmp/f3322.txt)
                                if [ "$ftag" == "!active" ] || [ "$ftag" == "nohost" ]; then
                                        logger "[F3322]请检查账号密码服务器是否准确"
                                        exit 1
                                fi
                        fi
        else
            exit 1
        fi
    write_cron_job
}

stop_f3322(){
    kill_cron_job
}

write_cron_job(){
    #每x分钟检查一次
    cru a f3322  "*/$F3322_INTERVAL * * * * $(readlink -f "$0")"
}

kill_cron_job() {
        if [ -n "$(cru l | grep f3322)" ]; then
                logger 删除f3322定时更新任务...
                cru d f3322
                #sed -i '/f3322/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
        fi
}

case $action in
start)
        logger "[F3322]: 开始执行F3322更新脚本，脚本会自动更新DDNS自动添加定时任务"
        start_f3322
        ;;
stop)
        logger "stop_f3322"
        stop_f3322
        ;;
*)
        start_f3322
        ;;
